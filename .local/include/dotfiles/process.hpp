#pragma once

#include "unique_fd.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <spawn.h>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace dotfiles {

struct CommandResult {
    int exit_code{-1};
    std::string output;
    bool success{false};
    bool timed_out{false};
};

/// High-performance, bounded process execution helper using posix_spawnp and poll.
/// Avoids shell forks, prevents zombie leaks, and enforces timeouts.
[[nodiscard]] inline CommandResult run_command(
    char* const arguments[],
    int timeout_ms = 3000
) {
    CommandResult result;
    if (arguments == nullptr || arguments[0] == nullptr) {
        return result;
    }

    int pipe_fds[2] = {-1, -1};
    if (::pipe2(pipe_fds, O_CLOEXEC | O_NONBLOCK) != 0) {
        return result;
    }
    UniqueFd read_fd(pipe_fds[0]);
    UniqueFd write_fd(pipe_fds[1]);

    posix_spawn_file_actions_t actions;
    if (::posix_spawn_file_actions_init(&actions) != 0) {
        return result;
    }

    int action_error = ::posix_spawn_file_actions_addopen(
        &actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
    if (action_error == 0 && write_fd.get() != STDOUT_FILENO) {
        action_error = ::posix_spawn_file_actions_adddup2(&actions, write_fd.get(), STDOUT_FILENO);
    }
    if (action_error == 0) {
        action_error = ::posix_spawn_file_actions_addclose(&actions, read_fd.get());
    }
    if (action_error == 0 && write_fd.get() != STDOUT_FILENO) {
        action_error = ::posix_spawn_file_actions_addclose(&actions, write_fd.get());
    }
    if (action_error == 0) {
        action_error = ::posix_spawn_file_actions_addopen(
            &actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);
    }

    if (action_error != 0) {
        ::posix_spawn_file_actions_destroy(&actions);
        return result;
    }

    posix_spawnattr_t attr;
    bool has_attr = (::posix_spawnattr_init(&attr) == 0);
    if (has_attr) {
        ::posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);
        ::posix_spawnattr_setpgroup(&attr, 0);
    }

    pid_t pid = 0;
    const int spawn_error = ::posix_spawnp(
        &pid, arguments[0], &actions, has_attr ? &attr : nullptr, arguments, environ);
    ::posix_spawn_file_actions_destroy(&actions);
    if (has_attr) {
        ::posix_spawnattr_destroy(&attr);
    }
    write_fd.reset(); // Close write end in parent so EOF can be received

    if (spawn_error != 0 || pid <= 0) {
        return result;
    }

    auto terminate_child = [pid]() {
        ::kill(-pid, SIGKILL);
        ::kill(pid, SIGKILL);
        int st = 0;
        while (::waitpid(pid, &st, 0) < 0 && errno == EINTR) {}
    };

    // Read loop with poll-based timeout
    std::array<char, 1024> buffer{};
    auto start_time = std::chrono::steady_clock::now();
    const bool has_timeout = (timeout_ms >= 0);

    for (;;) {
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - start_time
        ).count();

        if (has_timeout && elapsed >= timeout_ms) {
            result.timed_out = true;
            terminate_child();
            return result;
        }

        int remaining_ms = has_timeout ? static_cast<int>(timeout_ms - elapsed) : -1;

        struct pollfd pfd{};
        pfd.fd = read_fd.get();
        pfd.events = POLLIN | POLLHUP | POLLERR;

        int poll_ret = ::poll(&pfd, 1, remaining_ms);
        if (poll_ret < 0) {
            if (errno == EINTR) {
                continue;
            }
            break;
        }
        if (poll_ret == 0) {
            // Timeout reached
            result.timed_out = true;
            terminate_child();
            return result;
        }

        if (pfd.revents & POLLIN) {
            bool eof_encountered = false;
            while (true) {
                const ssize_t bytes = ::read(read_fd.get(), buffer.data(), buffer.size());
                if (bytes > 0) {
                    result.output.append(buffer.data(), static_cast<std::size_t>(bytes));
                    continue;
                }
                if (bytes == 0) {
                    eof_encountered = true;
                    break;
                }
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    break; // Drained all currently available bytes
                }
                if (errno == EINTR) {
                    continue;
                }
                eof_encountered = true;
                break;
            }
            if (eof_encountered) {
                break;
            }
        }

        if (pfd.revents & (POLLHUP | POLLERR)) {
            // Read any lingering bytes before breaking
            while (true) {
                const ssize_t bytes = ::read(read_fd.get(), buffer.data(), buffer.size());
                if (bytes > 0) {
                    result.output.append(buffer.data(), static_cast<std::size_t>(bytes));
                } else {
                    break;
                }
            }
            break;
        }
    }

    read_fd.reset();

    int status = 0;
    pid_t wpid = 0;
    do {
        wpid = ::waitpid(pid, &status, 0);
    } while (wpid < 0 && errno == EINTR);

    if (wpid == pid) {
        if (WIFEXITED(status)) {
            result.exit_code = WEXITSTATUS(status);
            result.success = (result.exit_code == 0);
        } else if (WIFSIGNALED(status)) {
            result.exit_code = 128 + WTERMSIG(status);
        }
    }

    return result;
}

/// Convenience function returning only the trimmed output string of a command.
[[nodiscard]] inline std::string command_output(
    char* const arguments[],
    int timeout_ms = 3000
) {
    CommandResult res = run_command(arguments, timeout_ms);
    if (!res.success) {
        return {};
    }
    while (!res.output.empty() && (res.output.back() == '\n' || res.output.back() == '\r')) {
        res.output.pop_back();
    }
    return res.output;
}

} // namespace dotfiles
