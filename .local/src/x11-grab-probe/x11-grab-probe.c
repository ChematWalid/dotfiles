#include <X11/Xlib.h>
#include <stdio.h>

int main(void) {
    Display *d = XOpenDisplay(NULL);
    if (!d) {
        fprintf(stderr, "x11-grab-probe: could not open the X display\n");
        return 2;
    }
    Window root = DefaultRootWindow(d);
    
    // Check if pointer is actively grabbed (e.g., context menu, dropdown, combobox)
    int pgrab = XGrabPointer(d, root, False, 0, GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
    if (pgrab == AlreadyGrabbed || pgrab == GrabFrozen) {
        XCloseDisplay(d);
        return 1; // Grab active
    }
    if (pgrab != GrabSuccess) {
        fprintf(stderr, "x11-grab-probe: pointer grab failed with X status %d\n", pgrab);
        XCloseDisplay(d);
        return 2;
    }
    XUngrabPointer(d, CurrentTime);
    
    // Check if keyboard is actively grabbed
    int kgrab = XGrabKeyboard(d, root, False, GrabModeAsync, GrabModeAsync, CurrentTime);
    if (kgrab == AlreadyGrabbed || kgrab == GrabFrozen) {
        XCloseDisplay(d);
        return 1; // Grab active
    }
    if (kgrab != GrabSuccess) {
        fprintf(stderr, "x11-grab-probe: keyboard grab failed with X status %d\n", kgrab);
        XCloseDisplay(d);
        return 2;
    }
    XUngrabKeyboard(d, CurrentTime);
    
    XFlush(d);
    XCloseDisplay(d);
    return 0; // Free
}
