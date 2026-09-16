#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/Xproto.h>

static Display *ctrl_disp = NULL;
static Display *data_disp = NULL;
static char tray_pid[32] = {0};
static int safe_x1 = 1170, safe_y1 = 680, safe_x2 = 1366, safe_y2 = 768;

static void update_safe_bounds(Display *disp) {
    Window root = DefaultRootWindow(disp);
    Window parent, *children = NULL;
    unsigned int nchildren = 0;

    if (XQueryTree(disp, root, &root, &parent, &children, &nchildren) && children) {
        for (unsigned int i = 0; i < nchildren; ++i) {
            char *name = NULL;
            if (XFetchName(disp, children[i], &name) && name) {
                if (strstr(name, "polybar-tray")) {
                    XWindowAttributes attr;
                    if (XGetWindowAttributes(disp, children[i], &attr)) {
                        safe_x1 = attr.x - 15;
                        safe_y1 = attr.y - 15;
                        safe_x2 = attr.x + attr.width + 15;
                        safe_y2 = 768; // cover through the bottom of the screen (toggle button)
                    }
                    XFree(name);
                    break;
                }
                XFree(name);
            }
        }
        XFree(children);
    }
}

static void event_callback(XPointer priv, XRecordInterceptData *data) {
    (void)priv;
    if (!data) return;

    if (data->category == XRecordFromServer) {
        xEvent *event = (xEvent *)data->data;
        if (event && ((event->u.u.type & 0x7f) == ButtonPress)) {
            Window root, child;
            int root_x, root_y, win_x, win_y;
            unsigned int mask;

            if (XQueryPointer(ctrl_disp, DefaultRootWindow(ctrl_disp),
                              &root, &child, &root_x, &root_y, &win_x, &win_y, &mask)) {
                if (root_x < safe_x1 || root_x > safe_x2 || root_y < safe_y1 || root_y > safe_y2) {
                    char cmd[128];
                    snprintf(cmd, sizeof(cmd), "polybar-msg -p %s cmd hide >/dev/null 2>&1", tray_pid);
                    int ret = system(cmd);
                    (void)ret;
                    XRecordFreeData(data);
                    _exit(0);
                }
            }
        }
    }
    XRecordFreeData(data);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <tray_pid> [x1 y1 x2 y2]\n", argv[0]);
        return 1;
    }

    snprintf(tray_pid, sizeof(tray_pid), "%s", argv[1]);

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

    if (argc < 6) {
        update_safe_bounds(ctrl_disp);
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
