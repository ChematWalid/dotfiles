#include <X11/Xlib.h>
#include <stdio.h>

int main(void) {
    Display *d = XOpenDisplay(NULL);
    if (!d) return 2;
    Window root = DefaultRootWindow(d);
    
    // Check if pointer is actively grabbed (e.g., context menu, dropdown, combobox)
    int pgrab = XGrabPointer(d, root, False, 0, GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
    if (pgrab == AlreadyGrabbed) {
        XCloseDisplay(d);
        return 1; // Grab active
    }
    if (pgrab == GrabSuccess) {
        XUngrabPointer(d, CurrentTime);
    }
    
    // Check if keyboard is actively grabbed
    int kgrab = XGrabKeyboard(d, root, False, GrabModeAsync, GrabModeAsync, CurrentTime);
    if (kgrab == AlreadyGrabbed) {
        XCloseDisplay(d);
        return 1; // Grab active
    }
    if (kgrab == GrabSuccess) {
        XUngrabKeyboard(d, CurrentTime);
    }
    
    XFlush(d);
    XCloseDisplay(d);
    return 0; // Free
}
