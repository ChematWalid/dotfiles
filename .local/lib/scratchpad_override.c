#define _GNU_SOURCE
#include <X11/Xlib.h>
#include <dlfcn.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>

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

typedef int (*XMapWindow_fn)(Display*, Window);
static _Atomic(XMapWindow_fn) real_XMapWindow = NULL;
_Static_assert(sizeof(XMapWindow_fn) == sizeof(void*),
               "XMapWindow function pointers must match dlsym pointer size");

int XMapWindow(Display *dpy, Window w) {
    XMapWindow_fn real_map = atomic_load_explicit(&real_XMapWindow, memory_order_acquire);
    if (!real_map) {
        void *symbol = dlsym(RTLD_NEXT, "XMapWindow");
        XMapWindow_fn resolved = NULL;
        memcpy(&resolved, &symbol, sizeof(resolved));
        if (!resolved) {
            return 0;
        }

        XMapWindow_fn expected = NULL;
        if (atomic_compare_exchange_strong_explicit(
                &real_XMapWindow, &expected, resolved,
                memory_order_acq_rel, memory_order_acquire)) {
            real_map = resolved;
        } else {
            real_map = expected;
        }
    }

    /* Set override_redirect so i3 ignores this window completely */
    XSetWindowAttributes attrs;
    attrs.override_redirect = True;
    XChangeWindowAttributes(dpy, w, CWOverrideRedirect, &attrs);

    /* Center the window on the active display */
    int scr = DefaultScreen(dpy);
    int sw = DisplayWidth(dpy, scr);
    int sh = DisplayHeight(dpy, scr);
    const unsigned int width = 900U;
    const unsigned int height = 550U;
    int x = (sw - (int)width) / 2;
    int y = (sh - (int)height) / 2;
    if (x < 0) x = 0;
    if (y < 0) y = 0;

    XMoveResizeWindow(dpy, w, x, y, width, height);

    int ret = real_map(dpy, w);
    XSync(dpy, False);
    XSetInputFocus(dpy, w, RevertToParent, CurrentTime);
    return ret;
}
