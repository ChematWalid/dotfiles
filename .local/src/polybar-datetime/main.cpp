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

#include <sys/inotify.h>
#include <sys/timerfd.h>
#include <unistd.h>

namespace {

constexpr std::string_view state_filename = "polybar-datetime-state";

[[nodiscard]] constexpr bool has_event(short events, short event) noexcept {
    return (static_cast<unsigned short>(events) & static_cast<unsigned short>(event)) != 0;
}

struct StatePaths {
    std::string directory;
    std::string file;
};

StatePaths make_state_paths() {
    const char* runtime_directory = std::getenv("XDG_RUNTIME_DIR");
    const char* home_directory = std::getenv("HOME");

    std::string base_directory;
    if (runtime_directory != nullptr && runtime_directory[0] != '\0') {
        base_directory = runtime_directory;
    } else if (home_directory != nullptr && home_directory[0] != '\0') {
        base_directory = std::string{home_directory} + "/.cache";
    } else {
        base_directory = "/tmp";
    }

    StatePaths paths{base_directory + "/dotfiles", {}};
    paths.file = paths.directory + "/" + std::string{state_filename};
    std::error_code error;
    std::filesystem::create_directories(paths.directory, error);
    if (error) {
        throw std::system_error(error, "create Polybar datetime state directory");
    }
    return paths;
}

class FileDescriptor {
public:
    explicit FileDescriptor(int value) noexcept : value_(value) {}
    ~FileDescriptor() {
        if (value_ >= 0) {
            close(value_);
        }
    }

    FileDescriptor(const FileDescriptor&) = delete;
    FileDescriptor& operator=(const FileDescriptor&) = delete;
    FileDescriptor(FileDescriptor&& other) noexcept : value_(std::exchange(other.value_, -1)) {}
    FileDescriptor& operator=(FileDescriptor&&) = delete;

    [[nodiscard]] int get() const noexcept { return value_; }

private:
    int value_;
};

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
    std::string_view color = "#b4befe";
    if (mode == 1) {
        format = "%H:%M:%S";
        icon = "󰥔";
        color = "#cba6f7";
    } else if (mode == 2) {
        format = "%a, %d %b %Y";
        icon = "󰃭";
        color = "#89b4fa";
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
            throw std::system_error(errno, std::generic_category(), "read inotify events");
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

FileDescriptor make_second_timer() {
    FileDescriptor timer_fd{timerfd_create(CLOCK_REALTIME, TFD_CLOEXEC | TFD_NONBLOCK)};
    if (timer_fd.get() < 0) {
        throw std::system_error(errno, std::generic_category(), "create clock timer");
    }
    arm_second_timer(timer_fd.get());
    return timer_fd;
}

FileDescriptor make_state_watcher(const std::string& state_directory) {
    FileDescriptor inotify_fd{inotify_init1(IN_CLOEXEC | IN_NONBLOCK)};
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

int main() {
    std::setlocale(LC_TIME, "");

    try {
        const StatePaths state_paths = make_state_paths();
        const FileDescriptor timer_fd = make_second_timer();
        const FileDescriptor inotify_fd = make_state_watcher(state_paths.directory);
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
                        throw std::system_error(errno, std::generic_category(), "read clock timer");
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
