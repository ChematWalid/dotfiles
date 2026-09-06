#define _GNU_SOURCE
#include <X11/Xlib.h>
#include <dlfcn.h>
#include <stdlib.h>

/*
 * Scratchpad Override-Redirect Wrapper
 * Enables floating dropdown terminal on top of any window (including fullscreen)
 * without i3wm un-fullscreening the active window or disrupting workspace layouts.
 */

__attribute__((constructor))
static void init(void) {
    /* Prevent child shells/processes from inheriting LD_PRELOAD */
    unsetenv("LD_PRELOAD");
}

static int (*real_XMapWindow)(Display*, Window) = NULL;

int XMapWindow(Display *dpy, Window w) {
    if (!real_XMapWindow) {
        real_XMapWindow = dlsym(RTLD_NEXT, "XMapWindow");
    }

    /* Set override_redirect so i3 ignores this window completely */
    XSetWindowAttributes attrs;
    attrs.override_redirect = True;
    XChangeWindowAttributes(dpy, w, CWOverrideRedirect, &attrs);

    /* Center the window on the active display */
    int scr = DefaultScreen(dpy);
    int sw = DisplayWidth(dpy, scr);
    int sh = DisplayHeight(dpy, scr);
    int width = 900;
    int height = 550;
    int x = (sw - width) / 2;
    int y = (sh - height) / 2;
    if (x < 0) x = 0;
    if (y < 0) y = 0;

    XMoveResizeWindow(dpy, w, x, y, width, height);

    int ret = real_XMapWindow(dpy, w);
    XSync(dpy, False);
    XSetInputFocus(dpy, w, RevertToParent, CurrentTime);
    return ret;
}
