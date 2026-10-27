#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <cstdlib>
#include <iostream>
#include <spawn.h>
#include <string_view>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

int main(int argc, char* argv[]) {
    bool notify = false;
    std::string_view command = "toggle";

    for (int i = 1; i < argc; ++i) {
        std::string_view arg(argv[i]);
        if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: xkb-group-toggle [get|toggle|0|1|be|ara] [--notify|-n]\n";
            return 0;
        }
        if (arg == "--notify" || arg == "-n") {
            notify = true;
        } else {
            command = arg;
        }
    }

    int reason = 0;
    int major = XkbMajorVersion;
    int minor = XkbMinorVersion;
    Display* dpy = XkbOpenDisplay(nullptr, nullptr, nullptr, &major, &minor, &reason);
    if (!dpy) {
        dpy = XOpenDisplay(nullptr);
        if (!dpy) {
            std::cerr << "xkb-group-toggle: unable to open X11 display\n";
            return 1;
        }
    }

    XkbStateRec state;
    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        std::cerr << "xkb-group-toggle: unable to retrieve XKB state\n";
        XCloseDisplay(dpy);
        return 1;
    }

    int cur_group = static_cast<int>(state.group);
    int target_group = (cur_group == 0) ? 1 : 0;

    if (command == "get" || command == "--get") {
        std::cout << cur_group << '\n';
        XCloseDisplay(dpy);
        return 0;
    }
    if (command == "toggle" || command == "--toggle") {
        target_group = (cur_group == 0) ? 1 : 0;
    } else if (command == "0" || command == "be") {
        target_group = 0;
    } else if (command == "1" || command == "ara") {
        target_group = 1;
    } else {
        std::cerr << "Usage: xkb-group-toggle [get|toggle|0|1|be|ara] [--notify|-n]\n";
        XCloseDisplay(dpy);
        return 2;
    }

    if (!XkbLockGroup(dpy, XkbUseCoreKbd, static_cast<unsigned int>(target_group))) {
        std::cerr << "xkb-group-toggle: XkbLockGroup failed\n";
        XCloseDisplay(dpy);
        return 1;
    }

    XSync(dpy, False);
    XCloseDisplay(dpy);

    std::cout << target_group << '\n';

    if (notify) {
        const char* layout_str = (target_group == 1) ? "🇸🇦 Arabic (العربية)" : "🇧🇪 Belgian (AZERTY)";
        char arg0[] = "dunstify";
        char arg1[] = "-a";
        char arg2[] = "Keyboard";
        char arg3[] = "-r";
        char arg4[] = "9993";
        char arg5[] = "-u";
        char arg6[] = "low";
        char arg7[] = "-i";
        char arg8[] = "input-keyboard";
        char arg9[] = "Keyboard Layout";
        char* arg10 = const_cast<char*>(layout_str);
        char arg11[] = "-t";
        char arg12[] = "1500";
        char* const d_args[] = {arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, nullptr};
        pid_t p = 0;
        if (::posix_spawnp(&p, "dunstify", nullptr, nullptr, d_args, environ) == 0) {
            ::waitpid(p, nullptr, 0);
        }
    }

    return 0;
}
