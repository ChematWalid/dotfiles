#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <spawn.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/Xproto.h>

static Display *ctrl_disp = NULL;
static Display *data_disp = NULL;
static char tray_pid[32] = {0};
static char state_path[4096] = {0};
static Window toggle_window = None;
static Window tray_window = None;
static struct timespec start_time;
extern char **environ;

static int on_x_error(Display *d, XErrorEvent *e) {
    (void)d;
    (void)e;
    return 0;
}

static void hide_tray_and_exit(void) {
    if (tray_window != None && ctrl_disp != NULL) {
        XUnmapWindow(ctrl_disp, tray_window);
        XSync(ctrl_disp, False);
    } else if (tray_pid[0] != '\0') {
        char *const args[] = {"polybar-msg", "-p", tray_pid, "cmd", "hide", NULL};
        pid_t child;
        (void)posix_spawnp(&child, args[0], NULL, NULL, args, environ);
    }

    if (state_path[0] != '\0') {
        int fd = open(state_path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
        if (fd >= 0) {
            (void)write(fd, "hidden\n", 7);
            close(fd);
        }
    }
    _exit(0);
}

static void event_callback(XPointer priv, XRecordInterceptData *data) {
    (void)priv;
    if (!data) return;

    if (data->category == XRecordFromServer) {
        xEvent *event = (xEvent *)data->data;
        if (event && (((unsigned char)event->u.u.type & 0x7fU) == ButtonPress)) {
            // Check startup grace period (150ms) to avoid catching the click that launched this watcher
            struct timespec now;
            clock_gettime(CLOCK_MONOTONIC, &now);
            long long elapsed_ms = (long long)(now.tv_sec - start_time.tv_sec) * 1000LL +
                                   (long long)(now.tv_nsec - start_time.tv_nsec) / 1000000LL;
            if (elapsed_ms < 150) {
                XRecordFreeData(data);
                return;
            }

            int click_x = event->u.keyButtonPointer.rootX;
            int click_y = event->u.keyButtonPointer.rootY;

            // Fallback to XQueryPointer if event coordinates are 0
            if (click_x == 0 && click_y == 0 && ctrl_disp != NULL) {
                Window root_ret, child_ret;
                int rx = 0, ry = 0, wx = 0, wy = 0;
                unsigned int mask = 0;
                if (XQueryPointer(ctrl_disp, DefaultRootWindow(ctrl_disp),
                                  &root_ret, &child_ret, &rx, &ry, &wx, &wy, &mask)) {
                    click_x = rx;
                    click_y = ry;
                }
            }

            // Check if click occurred inside the tray bounding box
            if (tray_window != None && ctrl_disp != NULL) {
                Window root_ret;
                int x_ret = 0, y_ret = 0;
                unsigned int w = 0, h = 0, border = 0, depth = 0;
                if (XGetGeometry(ctrl_disp, tray_window, &root_ret, &x_ret, &y_ret, &w, &h, &border, &depth)) {
                    Window child;
                    int tray_root_x = 0, tray_root_y = 0;
                    XTranslateCoordinates(ctrl_disp, tray_window, root_ret, 0, 0, &tray_root_x, &tray_root_y, &child);

                    int min_x = tray_root_x;
                    int max_x = tray_root_x + (int)w + (int)(2 * border);
                    int min_y = tray_root_y;
                    int max_y = tray_root_y + (int)h + (int)(2 * border);

                    if (click_x >= min_x && click_x < max_x && click_y >= min_y && click_y < max_y) {
                        // User clicked a tray icon inside stalonetray; keep tray open
                        XRecordFreeData(data);
                        return;
                    }
                }
            }

            // Check if click occurred on the tray toggle arrow on Polybar.
            // If so, let toggle-tray.sh handle closing so there is no toggle oscillation.
            if (toggle_window != None && ctrl_disp != NULL) {
                Window root_ret;
                int bar_x = 0, bar_y = 0;
                unsigned int bar_w = 0, bar_h = 0, border = 0, depth = 0;
                if (XGetGeometry(ctrl_disp, toggle_window, &root_ret, &bar_x, &bar_y, &bar_w, &bar_h, &border, &depth)) {
                    Window child;
                    int bar_root_x = 0, bar_root_y = 0;
                    XTranslateCoordinates(ctrl_disp, toggle_window, root_ret, 0, 0, &bar_root_x, &bar_root_y, &child);

                    // Toggle arrow is positioned right before the powermenu at the far right of Polybar
                    int arrow_min_x = bar_root_x + (int)bar_w - 105;
                    int arrow_max_x = bar_root_x + (int)bar_w - 35;
                    int arrow_min_y = bar_root_y;
                    int arrow_max_y = bar_root_y + (int)bar_h;

                    if (click_x >= arrow_min_x && click_x <= arrow_max_x &&
                        click_y >= arrow_min_y && click_y <= arrow_max_y) {
                        // Click is on the tray toggle module; let toggle-tray.sh handle it
                        XRecordFreeData(data);
                        return;
                    }
                }
            }

            // Click is outside the tray window: hide tray and exit
            XRecordFreeData(data);
            hide_tray_and_exit();
        }
    }
    XRecordFreeData(data);
}

int main(int argc, char *argv[]) {
    if (argc >= 2) {
        snprintf(tray_pid, sizeof(tray_pid), "%s", argv[1]);
    }
    if (argc >= 3) {
        toggle_window = (Window)strtoul(argv[2], NULL, 0);
    }
    if (argc >= 4) {
        snprintf(state_path, sizeof(state_path), "%s", argv[3]);
    }
    if (argc >= 5) {
        tray_window = (Window)strtoul(argv[4], NULL, 0);
    }

    clock_gettime(CLOCK_MONOTONIC, &start_time);

    ctrl_disp = XOpenDisplay(NULL);
    data_disp = XOpenDisplay(NULL);

    if (!ctrl_disp || !data_disp) {
        return 1;
    }

    XSetErrorHandler(on_x_error);

    XRecordRange *range = XRecordAllocRange();
    if (!range) {
        return 1;
    }

    range->device_events.first = ButtonPress;
    range->device_events.last  = ButtonPress;
    range->delivered_events.first = ButtonPress;
    range->delivered_events.last  = ButtonPress;

    XRecordClientSpec client_spec = XRecordAllClients;
    XRecordContext ctx = XRecordCreateContext(ctrl_disp, 0, &client_spec, 1, &range, 1);
    XFree(range);

    if (!ctx) {
        return 1;
    }

    XSync(ctrl_disp, False);
    XRecordEnableContext(data_disp, ctx, event_callback, NULL);

    _exit(0);
    return 0;
}
