#include <array>
#include <cerrno>
#include <clocale>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <poll.h>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

#include <dotfiles/catppuccin.hpp>
#include <dotfiles/event_utils.hpp>
#include <dotfiles/state_paths.hpp>
#include <dotfiles/unique_fd.hpp>

#include <sys/inotify.h>
#include <sys/timerfd.h>
#include <unistd.h>

namespace {

using dotfiles::has_event;
using dotfiles::UniqueFd;

constexpr std::string_view state_filename = "polybar-datetime-state";

int read_mode(const std::string& state_path) {
    std::ifstream state_file{state_path};
    int mode = 0;
    if (state_file >> mode && (mode == 1 || mode == 2)) {
        return mode;
    }
    return 0;
}

std::string format_output(int mode) {
    const std::time_t now = std::time(nullptr);
    std::tm local_time{};
    if (now == static_cast<std::time_t>(-1) || localtime_r(&now, &local_time) == nullptr) {
        return {};
    }

    std::array<char, 128> buffer{};
    const char* format = "%d %b %H:%M:%S";
    std::string_view icon = "󰃰";
    std::string_view color = dotfiles::colors::lavender;
    if (mode == 1) {
        format = "%H:%M:%S";
        icon = "󰥔";
        color = dotfiles::colors::mauve;
    } else if (mode == 2) {
        format = "%a, %d %b %Y";
        icon = "󰃭";
        color = dotfiles::colors::blue;
    }

    if (std::strftime(buffer.data(), buffer.size(), format, &local_time) == 0) {
        return {};
    }

    std::string output;
    output.reserve(128);
    output.append("%{F").append(color).append("}");
    output.append(icon).append("%{F-} ").append(buffer.data());
    return output;
}

void emit_if_changed(int mode, std::string& previous) {
    std::string output = format_output(mode);
    if (!output.empty() && output != previous) {
        std::cout << output << '\n' << std::flush;
        previous = std::move(output);
    }
}

bool state_file_changed(int inotify_fd) {
    alignas(inotify_event) std::array<char, 4096> buffer{};
    bool changed = false;

    for (;;) {
        const ssize_t bytes_read = read(inotify_fd, buffer.data(), buffer.size());
        if (bytes_read < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return changed;
            }
            return changed;
        }
        if (bytes_read == 0) {
            return changed;
        }

        std::size_t offset = 0;
        const auto total_bytes = static_cast<std::size_t>(bytes_read);
        while (offset + sizeof(inotify_event) <= total_bytes) {
            const auto* event = reinterpret_cast<const inotify_event*>(buffer.data() + offset);
            const std::size_t event_size = sizeof(inotify_event) + event->len;
            if (offset + event_size > total_bytes) {
                break;
            }
            if (event->len > 0) {
                const std::size_t name_len = ::strnlen(event->name, event->len);
                if (std::string_view{event->name, name_len} == state_filename) {
                    changed = true;
                }
            }
            offset += event_size;
        }
    }
}

void arm_second_timer(int timer_fd) {
    timespec now{};
    if (clock_gettime(CLOCK_REALTIME, &now) < 0) {
        throw std::system_error(errno, std::generic_category(), "read system clock");
    }

    itimerspec timer{};
    timer.it_value.tv_sec = now.tv_sec + 1;
    timer.it_value.tv_nsec = 0;
    timer.it_interval.tv_sec = 1;
    timer.it_interval.tv_nsec = 0;

    if (timerfd_settime(timer_fd, TFD_TIMER_ABSTIME | TFD_TIMER_CANCEL_ON_SET, &timer, nullptr) < 0) {
        throw std::system_error(errno, std::generic_category(), "arm clock timer");
    }
}

UniqueFd make_second_timer() {
    UniqueFd timer_fd{timerfd_create(CLOCK_REALTIME, TFD_CLOEXEC | TFD_NONBLOCK)};
    if (timer_fd.get() < 0) {
        throw std::system_error(errno, std::generic_category(), "create clock timer");
    }
    arm_second_timer(timer_fd.get());
    return timer_fd;
}

UniqueFd make_state_watcher(const std::string& state_directory) {
    UniqueFd inotify_fd{inotify_init1(IN_CLOEXEC | IN_NONBLOCK)};
    if (inotify_fd.get() < 0) {
        throw std::system_error(errno, std::generic_category(), "create state watcher");
    }

    constexpr std::uint32_t mask =
        IN_CLOSE_WRITE | IN_MOVED_TO | IN_MOVED_FROM | IN_CREATE | IN_DELETE | IN_ATTRIB;
    if (inotify_add_watch(inotify_fd.get(), state_directory.c_str(), mask) < 0) {
        throw std::system_error(errno, std::generic_category(), "watch state directory");
    }
    return inotify_fd;
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string_view arg{argv[1]};
        if (arg == "--toggle" || arg == "-t") {
            try {
                const dotfiles::StatePaths state_paths = dotfiles::make_state_paths(state_filename);
                int mode = read_mode(state_paths.file);
                int next_mode = (mode + 1) % 3;
                std::string tmp_file = state_paths.file + ".tmp." + std::to_string(::getpid());
                {
                    std::ofstream out{tmp_file};
                    out << next_mode << '\n';
                }
                std::error_code ec;
                std::filesystem::rename(tmp_file, state_paths.file, ec);
                return ec ? 1 : 0;
            } catch (const std::exception& e) {
                std::cerr << "polybar-datetime --toggle: " << e.what() << '\n';
                return 1;
            }
        }
        if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: polybar-datetime [--toggle|-t|-h|--help]\n";
            return 0;
        }
    }

    std::setlocale(LC_TIME, "");

    try {
        const dotfiles::StatePaths state_paths = dotfiles::make_state_paths(state_filename);
        const UniqueFd timer_fd = make_second_timer();
        const UniqueFd inotify_fd = make_state_watcher(state_paths.directory);
        int mode = read_mode(state_paths.file);
        std::string previous;
        emit_if_changed(mode, previous);

        std::array<pollfd, 2> watched_fds{{
            {timer_fd.get(), POLLIN, 0},
            {inotify_fd.get(), POLLIN, 0},
        }};

        for (;;) {
            const int ready = poll(watched_fds.data(), watched_fds.size(), -1);
            if (ready < 0) {
                if (errno == EINTR) {
                    continue;
                }
                throw std::system_error(errno, std::generic_category(), "wait for clock events");
            }

            if (has_event(watched_fds[0].revents, POLLERR | POLLHUP | POLLNVAL) ||
                has_event(watched_fds[1].revents, POLLERR | POLLHUP | POLLNVAL)) {
                throw std::system_error(EIO, std::generic_category(), "clock or state descriptor hangup/error");
            }

            const bool state_changed =
                has_event(watched_fds[1].revents, POLLIN) && state_file_changed(inotify_fd.get());
            if (state_changed) {
                mode = read_mode(state_paths.file);
            }

            const bool timer_expired = has_event(watched_fds[0].revents, POLLIN);
            if (timer_expired) {
                std::uint64_t expirations{};
                const ssize_t timer_bytes = read(timer_fd.get(), &expirations, sizeof(expirations));
                if (timer_bytes < 0) {
                    if (errno == ECANCELED) {
                        // Clock was changed discontinuously (e.g. NTP or suspend/resume).
                        // Must rearm the timerfd, otherwise read() will continue to fail with ECANCELED!
                        arm_second_timer(timer_fd.get());
                    } else if (errno != EINTR && errno != EAGAIN) {
                        arm_second_timer(timer_fd.get());
                    }
                }
                emit_if_changed(mode, previous);
            }
            if (state_changed && !timer_expired) {
                emit_if_changed(mode, previous);
            }
        }
    } catch (const std::exception& error) {
        std::cerr << "polybar-datetime: " << error.what() << '\n';
        return 1;
    }
}
