#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <cstdlib>
#include <iostream>
#include <string_view>

int main(int argc, char* argv[]) {
    Display* dpy = XOpenDisplay(nullptr);
    if (!dpy) {
        std::cerr << "xkb-group-toggle: unable to open X11 display\n";
        return 1;
    }

    XkbStateRec state;
    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        std::cerr << "xkb-group-toggle: unable to retrieve XKB state\n";
        XCloseDisplay(dpy);
        return 1;
    }

    int cur_group = static_cast<int>(state.group);
    int target_group = (cur_group == 0) ? 1 : 0;

    if (argc > 1) {
        std::string_view arg(argv[1]);
        if (arg == "get" || arg == "--get") {
            std::cout << cur_group << '\n';
            XCloseDisplay(dpy);
            return 0;
        }
        if (arg == "toggle" || arg == "--toggle") {
            target_group = (cur_group == 0) ? 1 : 0;
        } else if (arg == "0" || arg == "be") {
            target_group = 0;
        } else if (arg == "1" || arg == "ara") {
            target_group = 1;
        } else {
            std::cerr << "Usage: xkb-group-toggle [get|toggle|0|1|be|ara]\n";
            XCloseDisplay(dpy);
            return 2;
        }
    }

    if (!XkbLockGroup(dpy, XkbUseCoreKbd, static_cast<unsigned int>(target_group))) {
        std::cerr << "xkb-group-toggle: XkbLockGroup failed\n";
        XCloseDisplay(dpy);
        return 1;
    }

    XSync(dpy, False);
    XCloseDisplay(dpy);

    std::cout << target_group << '\n';
    return 0;
}
