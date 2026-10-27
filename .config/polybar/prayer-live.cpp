#include "include/catppuccin.hpp"
#include "include/event_utils.hpp"
#include "include/unique_fd.hpp"

#include <array>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fcntl.h>
#include <iostream>
#include <poll.h>
#include <spawn.h>
#include <string>
#include <string_view>
#include <sys/timerfd.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace {

struct PrayerSchedule {
    std::string date;
    std::string fajr_str{"--:--"};
    std::string dhuhr_str{"--:--"};
    std::string asr_str{"--:--"};
    std::string maghrib_str{"--:--"};
    std::string isha_str{"--:--"};

    int fajr_min{-1};
    int dhuhr_min{-1};
    int asr_min{-1};
    int maghrib_min{-1};
    int isha_min{-1};

    [[nodiscard]] bool is_valid() const noexcept {
        return fajr_min >= 0 && dhuhr_min >= 0 && asr_min >= 0 && maghrib_min >= 0 && isha_min >= 0;
    }
};

int parse_time_to_minutes(std::string_view time_str) {
    if (time_str.size() < 5 || time_str[2] != ':') {
        return -1;
    }
    int h = (time_str[0] - '0') * 10 + (time_str[1] - '0');
    int m = (time_str[3] - '0') * 10 + (time_str[4] - '0');
    if (h < 0 || h > 23 || m < 0 || m > 59) {
        return -1;
    }
    return h * 60 + m;
}

std::string format_remaining(int rem_min) {
    if (rem_min < 0) {
        rem_min = 0;
    }
    int h = rem_min / 60;
    int m = rem_min % 60;
    char buf[32];
    if (h > 0) {
        std::snprintf(buf, sizeof(buf), "%dh %02dm", h, m);
    } else {
        std::snprintf(buf, sizeof(buf), "%dm", m);
    }
    return buf;
}

bool fetch_schedule(PrayerSchedule& sched) {
    int pipe_fds[2];
    if (::pipe2(pipe_fds, O_CLOEXEC) != 0) {
        return false;
    }

    posix_spawn_file_actions_t actions;
    if (::posix_spawn_file_actions_init(&actions) != 0) {
        ::close(pipe_fds[0]);
        ::close(pipe_fds[1]);
        return false;
    }

    ::posix_spawn_file_actions_adddup2(&actions, pipe_fds[1], STDOUT_FILENO);
    ::posix_spawn_file_actions_addclose(&actions, pipe_fds[0]);

    char arg0[] = "muslimtify";
    char arg1[] = "show";
    char arg2[] = "--headless";
    char* const args[] = {arg0, arg1, arg2, nullptr};

    pid_t pid = 0;
    int spawn_res = ::posix_spawnp(&pid, "muslimtify", &actions, nullptr, args, environ);
    ::posix_spawn_file_actions_destroy(&actions);
    ::close(pipe_fds[1]);

    if (spawn_res != 0) {
        ::close(pipe_fds[0]);
        return false;
    }

    std::string output;
    std::array<char, 512> buf{};
    ssize_t bytes_read = 0;
    while ((bytes_read = ::read(pipe_fds[0], buf.data(), buf.size())) > 0) {
        output.append(buf.data(), static_cast<std::size_t>(bytes_read));
    }
    ::close(pipe_fds[0]);

    int status = 0;
    ::waitpid(pid, &status, 0);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        return false;
    }

    // Parse key=value lines
    std::size_t pos = 0;
    while (pos < output.size()) {
        std::size_t next_line = output.find('\n', pos);
        if (next_line == std::string::npos) {
            next_line = output.size();
        }
        std::string_view line{output.data() + pos, next_line - pos};
        pos = next_line + 1;

        std::size_t eq = line.find('=');
        if (eq == std::string_view::npos) {
            continue;
        }
        std::string_view key = line.substr(0, eq);
        std::string_view val = line.substr(eq + 1);
        while (!val.empty() && (val.back() == '\r' || val.back() == ' ')) {
            val.remove_suffix(1);
        }

        if (key == "date") {
            sched.date = std::string(val);
        } else if (key == "fajr") {
            sched.fajr_str = std::string(val);
            sched.fajr_min = parse_time_to_minutes(val);
        } else if (key == "dhuhr") {
            sched.dhuhr_str = std::string(val);
            sched.dhuhr_min = parse_time_to_minutes(val);
        } else if (key == "asr") {
            sched.asr_str = std::string(val);
            sched.asr_min = parse_time_to_minutes(val);
        } else if (key == "maghrib") {
            sched.maghrib_str = std::string(val);
            sched.maghrib_min = parse_time_to_minutes(val);
        } else if (key == "isha") {
            sched.isha_str = std::string(val);
            sched.isha_min = parse_time_to_minutes(val);
        }
    }

    return sched.is_valid();
}

struct NextPrayerInfo {
    std::string name;
    std::string time_str;
    int remaining_min{0};
};

NextPrayerInfo calculate_next(const PrayerSchedule& sched, int now_min) {
    if (now_min < sched.fajr_min) {
        return {"Fajr", sched.fajr_str, sched.fajr_min - now_min};
    }
    if (now_min < sched.dhuhr_min) {
        return {"Dhuhr", sched.dhuhr_str, sched.dhuhr_min - now_min};
    }
    if (now_min < sched.asr_min) {
        return {"Asr", sched.asr_str, sched.asr_min - now_min};
    }
    if (now_min < sched.maghrib_min) {
        return {"Maghrib", sched.maghrib_str, sched.maghrib_min - now_min};
    }
    if (now_min < sched.isha_min) {
        return {"Isha", sched.isha_str, sched.isha_min - now_min};
    }
    // Next is Fajr tomorrow
    int rem = (24 * 60 - now_min) + sched.fajr_min;
    return {"Fajr", sched.fajr_str, rem};
}

void show_popup(const PrayerSchedule& sched, int now_min) {
    NextPrayerInfo next = calculate_next(sched, now_min);
    std::string rem_str = format_remaining(next.remaining_min);

    std::string body =
        "🌅 Fajr:       " + sched.fajr_str + "\n" +
        "☀️ Dhuhr:     " + sched.dhuhr_str + "\n" +
        "🌤️ Asr:       " + sched.asr_str + "\n" +
        "🌇 Maghrib:   " + sched.maghrib_str + "\n" +
        "🌙 Isha:      " + sched.isha_str + "\n\n" +
        "⏳ Next: " + next.name + " in " + rem_str;

    char arg0[] = "notify-send";
    char arg1[] = "-a";
    char arg2[] = "Muslimtify";
    char arg3[] = "-i";
    char arg4[] = "muslimtify";
    char arg5[] = "-u";
    char arg6[] = "normal";
    char arg7[] = "-t";
    char arg8[] = "8000";
    char arg9[] = "🕌 Today's Prayer Times";
    char* arg10 = body.data();
    char* const args[] = {arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, nullptr};

    pid_t pid = 0;
    if (::posix_spawnp(&pid, "notify-send", nullptr, nullptr, args, environ) == 0) {
        ::waitpid(pid, nullptr, 0);
    }
}

dotfiles::UniqueFd setup_minute_timer() {
    int tfd = ::timerfd_create(CLOCK_REALTIME, TFD_CLOEXEC | TFD_NONBLOCK);
    if (tfd < 0) {
        return dotfiles::UniqueFd(-1);
    }

    struct timespec now {};
    ::clock_gettime(CLOCK_REALTIME, &now);

    // Align timer to the next 30-second boundary
    time_t next_sec = ((now.tv_sec / 30) + 1) * 30;
    struct itimerspec its {};
    its.it_value.tv_sec = next_sec;
    its.it_value.tv_nsec = 0;
    its.it_interval.tv_sec = 30;
    its.it_interval.tv_nsec = 0;

    if (::timerfd_settime(tfd, TFD_TIMER_ABSTIME, &its, nullptr) != 0) {
        ::close(tfd);
        return dotfiles::UniqueFd(-1);
    }

    return dotfiles::UniqueFd(tfd);
}

} // namespace

int main(int argc, char* argv[]) {
    PrayerSchedule sched;
    if (!fetch_schedule(sched)) {
        std::cout << "%{F" << dotfiles::colors::overlay0 << "}🕌 --:--%{F-}\n" << std::flush;
        return 0;
    }

    std::time_t now = std::time(nullptr);
    std::tm tm_now {};
    localtime_r(&now, &tm_now);
    int now_min = tm_now.tm_hour * 60 + tm_now.tm_min;

    if (argc > 1) {
        std::string_view arg{argv[1]};
        if (arg == "--popup" || arg == "-p") {
            show_popup(sched, now_min);
            return 0;
        }
        if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: prayer-live [--tail|--popup|-p|-h]\n";
            return 0;
        }
    }

    // Default: tail mode for Polybar
    dotfiles::UniqueFd timer_fd = setup_minute_timer();
    int current_day = tm_now.tm_mday;

    for (;;) {
        now = std::time(nullptr);
        localtime_r(&now, &tm_now);
        now_min = tm_now.tm_hour * 60 + tm_now.tm_min;

        // Day changed: refresh prayer times from muslimtify
        if (tm_now.tm_mday != current_day) {
            current_day = tm_now.tm_mday;
            (void)fetch_schedule(sched);
        }

        NextPrayerInfo next = calculate_next(sched, now_min);
        std::string rem_str = format_remaining(next.remaining_min);

        // Output matching Polybar format
        std::cout << "%{F" << dotfiles::colors::teal << "}🕌%{F-} "
                  << next.name << " " << next.time_str << " %{F"
                  << dotfiles::colors::overlay0 << "}(" << rem_str << ")%{F-}\n"
                  << std::flush;

        if (timer_fd.valid()) {
            struct pollfd pfd {};
            pfd.fd = timer_fd.get();
            pfd.events = POLLIN;
            if (::poll(&pfd, 1, -1) > 0 && (pfd.revents & POLLIN)) {
                uint64_t expirations = 0;
                (void)::read(timer_fd.get(), &expirations, sizeof(expirations));
            }
        } else {
            ::sleep(30);
        }
    }
}
