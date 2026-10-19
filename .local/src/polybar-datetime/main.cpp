#include <array>
#include <cerrno>
#include <clocale>
#include <cstdint>
#include <cstring>
#include <ctime>
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

constexpr std::string_view state_path = "/tmp/polybar-datetime-state";
constexpr std::string_view state_directory = "/tmp";
constexpr std::string_view state_filename = "polybar-datetime-state";

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

int read_mode() {
    std::ifstream state_file{std::string{state_path}};
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

    std::array<char, 64> buffer{};
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
    return "%{F" + std::string{color} + "}" + std::string{icon} + "%{F-} " + buffer.data();
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
            if (errno == EAGAIN) {
                return changed;
            }
            throw std::system_error(errno, std::generic_category(), "read inotify events");
        }
        if (bytes_read == 0) {
            return changed;
        }

        for (std::size_t offset = 0; offset < static_cast<std::size_t>(bytes_read);) {
            const auto* event = reinterpret_cast<const inotify_event*>(buffer.data() + offset);
            if (event->len > 0 && std::string_view{event->name} == state_filename) {
                changed = true;
            }
            offset += sizeof(inotify_event) + event->len;
        }
    }
}

FileDescriptor make_second_timer() {
    FileDescriptor timer_fd{timerfd_create(CLOCK_REALTIME, TFD_CLOEXEC)};
    if (timer_fd.get() < 0) {
        throw std::system_error(errno, std::generic_category(), "create clock timer");
    }

    timespec now{};
    if (clock_gettime(CLOCK_REALTIME, &now) < 0) {
        throw std::system_error(errno, std::generic_category(), "read system clock");
    }

    constexpr long nanoseconds_per_second = 1'000'000'000L;
    const long delay = nanoseconds_per_second - now.tv_nsec;
    itimerspec timer{};
    timer.it_value.tv_sec = delay / nanoseconds_per_second;
    timer.it_value.tv_nsec = delay % nanoseconds_per_second;
    timer.it_interval.tv_sec = 1;

    if (timerfd_settime(timer_fd.get(), 0, &timer, nullptr) < 0) {
        throw std::system_error(errno, std::generic_category(), "arm clock timer");
    }
    return timer_fd;
}

FileDescriptor make_state_watcher() {
    FileDescriptor inotify_fd{inotify_init1(IN_CLOEXEC | IN_NONBLOCK)};
    if (inotify_fd.get() < 0) {
        throw std::system_error(errno, std::generic_category(), "create state watcher");
    }

    constexpr std::uint32_t mask = IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE | IN_DELETE;
    if (inotify_add_watch(inotify_fd.get(), state_directory.data(), mask) < 0) {
        throw std::system_error(errno, std::generic_category(), "watch state directory");
    }
    return inotify_fd;
}

}  // namespace

int main() {
    std::setlocale(LC_TIME, "");

    try {
        const FileDescriptor timer_fd = make_second_timer();
        const FileDescriptor inotify_fd = make_state_watcher();
        int mode = read_mode();
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

            const bool state_changed =
                (watched_fds[1].revents & POLLIN) != 0 && state_file_changed(inotify_fd.get());
            if (state_changed) {
                mode = read_mode();
            }

            const bool timer_expired = (watched_fds[0].revents & POLLIN) != 0;
            if (timer_expired) {
                std::uint64_t expirations{};
                if (read(timer_fd.get(), &expirations, sizeof(expirations)) < 0 && errno != EINTR) {
                    throw std::system_error(errno, std::generic_category(), "read clock timer");
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
