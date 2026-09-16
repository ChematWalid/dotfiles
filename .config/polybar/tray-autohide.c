#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/Xproto.h>

static Display *ctrl_disp = NULL;
static Display *data_disp = NULL;
static char tray_pid[32] = {0};
static int safe_x1 = 1160, safe_y1 = 670, safe_x2 = 1366, safe_y2 = 768;
static struct timespec start_time;

static long long get_elapsed_ms(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (now.tv_sec - start_time.tv_sec) * 1000LL + (now.tv_nsec - start_time.tv_nsec) / 1000000LL;
}

static void hide_tray_and_exit(void) {
    char cmd[128];
    if (tray_pid[0] != '\0') {
        snprintf(cmd, sizeof(cmd), "polybar-msg -p %s cmd hide >/dev/null 2>&1", tray_pid);
    } else {
        snprintf(cmd, sizeof(cmd), "polybar-msg -p $(pgrep -f 'polybar tray' | head -1) cmd hide >/dev/null 2>&1");
    }
    int ret = system(cmd);
    (void)ret;
    _exit(0);
}

static void event_callback(XPointer priv, XRecordInterceptData *data) {
    (void)priv;
    if (!data) return;

    if (data->category == XRecordFromServer) {
        xEvent *event = (xEvent *)data->data;
        if (event && ((event->u.u.type & 0x7f) == ButtonPress)) {
            // Read root coordinates directly from the wire event structure
            int root_x = event->u.keyButtonPointer.rootX;
            int root_y = event->u.keyButtonPointer.rootY;

            // Debounce: ignore clicks within the first 80ms if inside the toggle button
            if (get_elapsed_ms() < 80 && (root_x >= safe_x1 && root_y >= safe_y1)) {
                XRecordFreeData(data);
                return;
            }

            // If click is OUTSIDE the safe bounds of the popup tray and chevron:
            if (root_x < safe_x1 || root_x > safe_x2 || root_y < safe_y1 || root_y > safe_y2) {
                XRecordFreeData(data);
                hide_tray_and_exit();
            }
        }
    }
    XRecordFreeData(data);
}

int main(int argc, char *argv[]) {
    clock_gettime(CLOCK_MONOTONIC, &start_time);

    if (argc >= 2) {
        snprintf(tray_pid, sizeof(tray_pid), "%s", argv[1]);
    }

    if (argc >= 6) {
        safe_x1 = atoi(argv[2]);
        safe_y1 = atoi(argv[3]);
        safe_x2 = atoi(argv[4]);
        safe_y2 = atoi(argv[5]);
    }

    ctrl_disp = XOpenDisplay(NULL);
    data_disp = XOpenDisplay(NULL);

    if (!ctrl_disp || !data_disp) {
        return 1;
    }

    XRecordRange *range = XRecordAllocRange();
    if (!range) {
        return 1;
    }

    range->device_events.first = ButtonPress;
    range->device_events.last  = ButtonPress;

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
