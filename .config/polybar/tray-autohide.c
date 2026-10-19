#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <signal.h>
#include <time.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/Xproto.h>

static Display *ctrl_disp = NULL;
static Display *data_disp = NULL;
static char tray_pid[32] = {0};
static struct timespec start_time;
extern char **environ;

static long long get_elapsed_ms(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (now.tv_sec - start_time.tv_sec) * 1000LL + (now.tv_nsec - start_time.tv_nsec) / 1000000LL;
}

static void hide_tray_and_exit(void) {
    if (tray_pid[0] == '\0') {
        _exit(1);
    }

    char *const args[] = {"polybar-msg", "-p", tray_pid, "cmd", "hide", NULL};
    pid_t child;
    int result = posix_spawnp(&child, args[0], NULL, NULL, args, environ);
    _exit(result == 0 ? 0 : 1);
}

static void event_callback(XPointer priv, XRecordInterceptData *data) {
    (void)priv;
    if (!data) return;

    if (data->category == XRecordFromServer) {
        xEvent *event = (xEvent *)data->data;
        if (event && ((event->u.u.type & 0x7f) == ButtonRelease)) {
            // The toggle's opening click can still be in flight when this
            // watcher starts. Ignore that release; hide on the next click.
            if (get_elapsed_ms() < 80) {
                XRecordFreeData(data);
                return;
            }

            // Close after any completed click. This also lets tray icons
            // receive the press before the popup is unmapped on release.
            XRecordFreeData(data);
            hide_tray_and_exit();
        }
    }
    XRecordFreeData(data);
}

int main(int argc, char *argv[]) {
    clock_gettime(CLOCK_MONOTONIC, &start_time);

    if (argc >= 2) {
        snprintf(tray_pid, sizeof(tray_pid), "%s", argv[1]);
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
    range->device_events.last  = ButtonRelease;

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
