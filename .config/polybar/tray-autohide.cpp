#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include "include/state_paths.hpp"
#include "include/unique_fd.hpp"

#include <X11/Xlib.h>
#include <X11/Xproto.h>
#include <X11/Xutil.h>
#include <X11/extensions/record.h>

#include <array>
#include <chrono>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <spawn.h>
#include <string>
#include <string_view>
#include <sys/time.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace {

constexpr std::string_view tray_state_filename = "polybar-tray-visibility";
constexpr std::string_view pid_filename = "tray-autohide.pid";

static Display* ctrl_disp = nullptr;
static Display* data_disp = nullptr;
static Window tray_window = None;
static std::string g_state_path;
static std::string g_closed_path;
static std::string g_pid_path;
static struct timespec start_time;

int on_x_error(Display*, XErrorEvent*) {
    return 0;
}

long long get_now_ms() {
    struct timeval tv{};
    ::gettimeofday(&tv, nullptr);
    return static_cast<long long>(tv.tv_sec) * 1000LL + static_cast<long long>(tv.tv_usec) / 1000LL;
}

void write_state(std::string_view state) {
    if (g_state_path.empty()) return;
    std::string tmp = g_state_path + ".tmp." + std::to_string(::getpid());
    int fd = ::open(tmp.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    if (fd >= 0) {
        (void)::write(fd, state.data(), state.size());
        (void)::write(fd, "\n", 1);
        ::close(fd);
        ::rename(tmp.c_str(), g_state_path.c_str());
    }
}

void write_closed_at() {
    if (g_closed_path.empty()) return;
    long long now_ms = get_now_ms();
    std::string buf = std::to_string(now_ms) + "\n";
    int fd = ::open(g_closed_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    if (fd >= 0) {
        (void)::write(fd, buf.c_str(), buf.size());
        ::close(fd);
    }
}

void remove_closed_at() {
    if (!g_closed_path.empty()) {
        ::unlink(g_closed_path.c_str());
    }
}

void kill_existing_listener() {
    if (g_pid_path.empty()) return;
    std::ifstream f(g_pid_path);
    pid_t pid = 0;
    if (f >> pid && pid > 0) {
        if (pid != ::getpid()) {
            ::kill(pid, SIGTERM);
        }
    }
    ::unlink(g_pid_path.c_str());
}

void hide_tray_and_exit() {
    if (tray_window != None && ctrl_disp != nullptr) {
        XUnmapWindow(ctrl_disp, tray_window);
        XSync(ctrl_disp, False);
    }
    write_state("hidden");
    write_closed_at();
    if (!g_pid_path.empty()) {
        ::unlink(g_pid_path.c_str());
    }
    ::_exit(0);
}

void event_callback(XPointer, XRecordInterceptData* data) {
    if (!data) return;

    if (data->category == XRecordFromServer) {
        auto* event = reinterpret_cast<xEvent*>(data->data);
        if (event && (((unsigned char)event->u.u.type & 0x7fU) == ButtonPress)) {
            // Grace period: ignore clicks within first 50ms of launch
            struct timespec now{};
            clock_gettime(CLOCK_MONOTONIC, &now);
            long long elapsed_ms = static_cast<long long>(now.tv_sec - start_time.tv_sec) * 1000LL +
                                   static_cast<long long>(now.tv_nsec - start_time.tv_nsec) / 1000000LL;
            if (elapsed_ms < 50) {
                XRecordFreeData(data);
                return;
            }

            int click_x = event->u.keyButtonPointer.rootX;
            int click_y = event->u.keyButtonPointer.rootY;

            if (click_x == 0 && click_y == 0 && ctrl_disp != nullptr) {
                Window root_ret, child_ret;
                int rx = 0, ry = 0, wx = 0, wy = 0;
                unsigned int mask = 0;
                if (XQueryPointer(ctrl_disp, DefaultRootWindow(ctrl_disp),
                                  &root_ret, &child_ret, &rx, &ry, &wx, &wy, &mask)) {
                    click_x = rx;
                    click_y = ry;
                }
            }

            if (tray_window != None && ctrl_disp != nullptr) {
                Window root_ret;
                int x_ret = 0, y_ret = 0;
                unsigned int w = 0, h = 0, border = 0, depth = 0;
                if (XGetGeometry(ctrl_disp, tray_window, &root_ret, &x_ret, &y_ret, &w, &h, &border, &depth)) {
                    Window child;
                    int tray_root_x = 0, tray_root_y = 0;
                    XTranslateCoordinates(ctrl_disp, tray_window, root_ret, 0, 0, &tray_root_x, &tray_root_y, &child);

                    int min_x = tray_root_x;
                    int max_x = tray_root_x + static_cast<int>(w) + static_cast<int>(2 * border);
                    int min_y = tray_root_y;
                    int max_y = tray_root_y + static_cast<int>(h) + static_cast<int>(2 * border);

                    if (click_x >= min_x && click_x < max_x && click_y >= min_y && click_y < max_y) {
                        // Click is inside tray window: keep tray open
                        XRecordFreeData(data);
                        return;
                    }
                }
            }

            // Click is outside: hide tray and terminate listener
            XRecordFreeData(data);
            hide_tray_and_exit();
        }
    }
    XRecordFreeData(data);
}

void on_sigterm(int) {
    if (!g_pid_path.empty()) {
        ::unlink(g_pid_path.c_str());
    }
    ::_exit(0);
}

void run_listener(Window tray_win) {
    tray_window = tray_win;
    clock_gettime(CLOCK_MONOTONIC, &start_time);

    std::signal(SIGTERM, on_sigterm);
    std::signal(SIGINT, on_sigterm);

    ctrl_disp = XOpenDisplay(nullptr);
    data_disp = XOpenDisplay(nullptr);
    if (!ctrl_disp || !data_disp) {
        ::_exit(1);
    }

    XSetErrorHandler(on_x_error);

    XRecordRange* range = XRecordAllocRange();
    if (!range) {
        ::_exit(1);
    }
    range->device_events.first = ButtonPress;
    range->device_events.last  = ButtonPress;
    range->delivered_events.first = ButtonPress;
    range->delivered_events.last  = ButtonPress;

    XRecordClientSpec client_spec = XRecordAllClients;
    XRecordContext ctx = XRecordCreateContext(ctrl_disp, 0, &client_spec, 1, &range, 1);
    XFree(range);

    if (!ctx) {
        ::_exit(1);
    }

    XSync(ctrl_disp, False);
    XRecordEnableContext(data_disp, ctx, event_callback, nullptr);
    ::_exit(0);
}

struct X11Windows {
    Window tray{None};
    Window polybar_main{None};
};

X11Windows find_windows(Display* dpy) {
    X11Windows result{};
    Window root = DefaultRootWindow(dpy);
    Window parent = None;
    Window* children = nullptr;
    unsigned int nchildren = 0;

    if (!XQueryTree(dpy, root, &root, &parent, &children, &nchildren) || !children) {
        return result;
    }

    for (unsigned int i = 0; i < nchildren; ++i) {
        Window w = children[i];
        XClassHint ch{};
        if (XGetClassHint(dpy, w, &ch)) {
            if (ch.res_name && ch.res_class) {
                if (std::strcmp(ch.res_name, "stalonetray") == 0 &&
                    std::strcmp(ch.res_class, "stalonetray") == 0) {
                    result.tray = w;
                } else if (result.polybar_main == None &&
                           std::strcmp(ch.res_name, "polybar") == 0 &&
                           std::strcmp(ch.res_class, "Polybar") == 0) {
                    result.polybar_main = w;
                }
            }
            if (ch.res_name) XFree(ch.res_name);
            if (ch.res_class) XFree(ch.res_class);
        }
        if (result.tray != None && result.polybar_main != None) {
            break;
        }
    }

    XFree(children);
    return result;
}

void start_stalonetray() {
    const char* home = std::getenv("HOME");
    if (!home) return;
    std::string rc_path = std::string(home) + "/.config/polybar/stalonetrayrc";
    char arg0[] = "stalonetray";
    char arg1[] = "-c";
    char* arg2 = rc_path.data();
    char* const args[] = {arg0, arg1, arg2, nullptr};

    pid_t pid = 0;
    (void)::posix_spawnp(&pid, "stalonetray", nullptr, nullptr, args, environ);
}

} // namespace

int main(int argc, char* argv[]) {
    const auto state_paths = dotfiles::make_state_paths(tray_state_filename);
    g_state_path = state_paths.file;
    g_closed_path = state_paths.file + "-closed-at";
    g_pid_path = state_paths.directory + "/" + std::string(pid_filename);

    std::string_view action = "--toggle";
    if (argc >= 2) {
        action = argv[1];
    }

    // Legacy invocation: tray-autohide <pid|name> <toggle_win> <state_path> <tray_win>
    if (argc >= 5 && action != "--toggle" && action != "--hide" && action != "--status" && action != "--listen") {
        tray_window = static_cast<Window>(std::strtoul(argv[4], nullptr, 0));
        g_state_path = argv[3];
        g_closed_path = g_state_path + "-closed-at";
        run_listener(tray_window);
        return 0;
    }

    if (action == "--listen") {
        Window win = (argc >= 3) ? static_cast<Window>(std::strtoul(argv[2], nullptr, 0)) : None;
        if (win != None) {
            run_listener(win);
        }
        return 0;
    }

    Display* dpy = XOpenDisplay(nullptr);
    if (!dpy) {
        std::cerr << "tray-autohide: cannot open display\n";
        return 1;
    }
    XSetErrorHandler(on_x_error);

    X11Windows wins = find_windows(dpy);

    if (action == "--hide") {
        kill_existing_listener();
        if (wins.tray != None) {
            XUnmapWindow(dpy, wins.tray);
            XSync(dpy, False);
        }
        write_state("hidden");
        write_closed_at();
        XCloseDisplay(dpy);
        return 0;
    }

    if (action == "--status") {
        if (wins.tray != None) {
            XWindowAttributes attrs{};
            if (XGetWindowAttributes(dpy, wins.tray, &attrs) && attrs.map_state == IsViewable) {
                std::cout << "visible\n";
                XCloseDisplay(dpy);
                return 0;
            }
        }
        std::cout << "hidden\n";
        XCloseDisplay(dpy);
        return 0;
    }

    // Default: --toggle
    // Check closed-at debouncing
    std::ifstream closed_file(g_closed_path);
    long long last_closed = 0;
    if (closed_file >> last_closed) {
        long long diff = get_now_ms() - last_closed;
        if (diff >= 0 && diff < 500) {
            remove_closed_at();
            XCloseDisplay(dpy);
            return 0;
        }
    }
    remove_closed_at();

    bool just_started = false;
    if (wins.tray == None) {
        start_stalonetray();
        just_started = true;
        // Wait up to 1 second for stalonetray window to appear
        for (int i = 0; i < 20; ++i) {
            ::usleep(50000);
            wins = find_windows(dpy);
            if (wins.tray != None) break;
        }
    }

    if (wins.tray == None) {
        std::cerr << "tray-autohide: stalonetray window could not be found\n";
        XCloseDisplay(dpy);
        return 1;
    }

    XWindowAttributes attrs{};
    bool is_viewable = false;
    if (XGetWindowAttributes(dpy, wins.tray, &attrs)) {
        is_viewable = (attrs.map_state == IsViewable);
    }

    kill_existing_listener();

    if (!just_started && is_viewable) {
        // Tray is open -> HIDE IT
        XUnmapWindow(dpy, wins.tray);
        XSync(dpy, False);
        write_state("hidden");
        write_closed_at();
    } else {
        // Tray is closed -> SHOW IT & START LISTENER
        XMapRaised(dpy, wins.tray);
        XSync(dpy, False);
        write_state("visible");

        // Spawn background listener via fork
        pid_t child = ::fork();
        if (child == 0) {
            // Child process becomes daemon
            ::setsid();
            if (dpy) {
                ::close(ConnectionNumber(dpy));
            }
            int devnull = ::open("/dev/null", O_RDWR);
            if (devnull >= 0) {
                ::dup2(devnull, STDIN_FILENO);
                ::dup2(devnull, STDOUT_FILENO);
                ::dup2(devnull, STDERR_FILENO);
                if (devnull > 2) ::close(devnull);
            }
            run_listener(wins.tray);
            ::_exit(0);
        } else if (child > 0) {
            if (!g_pid_path.empty()) {
                std::ofstream pf(g_pid_path);
                pf << child << '\n';
            }
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
