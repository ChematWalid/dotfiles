#include <array>
#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <filesystem>
#include <iostream>
#include <poll.h>
#include <spawn.h>
#include <string>
#include <string_view>
#include <system_error>

#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <sys/inotify.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace {

constexpr std::string_view state_name{"polybar-network-state"};
constexpr std::string_view disconnected{"󰤭 Disconnected"};

class UniqueFd {
public:
    explicit UniqueFd(int fd) noexcept : fd_(fd) {}
    ~UniqueFd() {
        if (fd_ >= 0) {
            ::close(fd_);
        }
    }
    UniqueFd(const UniqueFd&) = delete;
    UniqueFd& operator=(const UniqueFd&) = delete;
    [[nodiscard]] int get() const noexcept { return fd_; }

private:
    int fd_;
};

[[nodiscard]] std::string command_output(char* const arguments[]) {
    std::array<int, 2> pipe_fds{};
    if (::pipe2(pipe_fds.data(), O_CLOEXEC) != 0) {
        return {};
    }

    posix_spawn_file_actions_t actions;
    if (::posix_spawn_file_actions_init(&actions) != 0) {
        ::close(pipe_fds[0]);
        ::close(pipe_fds[1]);
        return {};
    }
    int action_error = ::posix_spawn_file_actions_adddup2(&actions, pipe_fds[1], STDOUT_FILENO);
    if (action_error == 0) {
        action_error = ::posix_spawn_file_actions_addclose(&actions, pipe_fds[0]);
    }
    if (action_error == 0) {
        action_error = ::posix_spawn_file_actions_addclose(&actions, pipe_fds[1]);
    }
    if (action_error == 0) {
        action_error = ::posix_spawn_file_actions_addopen(
            &actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);
    }
    if (action_error != 0) {
        ::posix_spawn_file_actions_destroy(&actions);
        ::close(pipe_fds[0]);
        ::close(pipe_fds[1]);
        return {};
    }

    pid_t child{};
    const int spawn_error = ::posix_spawnp(
        &child, arguments[0], &actions, nullptr, arguments, environ);
    ::posix_spawn_file_actions_destroy(&actions);
    ::close(pipe_fds[1]);
    if (spawn_error != 0) {
        ::close(pipe_fds[0]);
        return {};
    }

    std::string output;
    std::array<char, 256> buffer{};
    for (;;) {
        const ssize_t bytes = ::read(pipe_fds[0], buffer.data(), buffer.size());
        if (bytes > 0) {
            output.append(buffer.data(), static_cast<std::size_t>(bytes));
            continue;
        }
        if (bytes < 0 && errno == EINTR) {
            continue;
        }
        break;
    }
    ::close(pipe_fds[0]);

    int status{};
    while (::waitpid(child, &status, 0) < 0 && errno == EINTR) {
    }
    while (!output.empty() && (output.back() == '\n' || output.back() == '\r')) {
        output.pop_back();
    }
    return output;
}

[[nodiscard]] std::string current_status(const std::filesystem::path& state_file) {
    if (std::filesystem::exists(state_file)) {
        char ip[] = "ip";
        char ipv4[] = "-4";
        char route_command[] = "route";
        char get[] = "get";
        char destination[] = "1.1.1.1";
        char* arguments[]{ip, ipv4, route_command, get, destination, nullptr};
        const auto route = command_output(arguments);
        const auto source = route.find(" src ");
        if (source == std::string::npos) {
            return std::string{disconnected};
        }
        const auto start = source + 5;
        const auto end = route.find(' ', start);
        const auto address = route.substr(start, end - start);
        return address.empty() ? std::string{disconnected} : "󰤨 " + address;
    }

    char iwgetid[] = "iwgetid";
    char raw_ssid[] = "-r";
    char* arguments[]{iwgetid, raw_ssid, nullptr};
    const auto ssid = command_output(arguments);
    return ssid.empty() ? std::string{disconnected} : "󰤨 " + ssid;
}

[[nodiscard]] bool has_relevant_route_event(const char* buffer, std::size_t size) {
    const char* cursor = buffer;
    std::size_t remaining = size;
    while (remaining >= sizeof(nlmsghdr)) {
        const auto* header = reinterpret_cast<const nlmsghdr*>(cursor);
        if (header->nlmsg_len < sizeof(nlmsghdr) || header->nlmsg_len > remaining) {
            break;
        }
        if (header->nlmsg_type == RTM_NEWLINK || header->nlmsg_type == RTM_DELLINK ||
            header->nlmsg_type == RTM_NEWADDR || header->nlmsg_type == RTM_DELADDR ||
            header->nlmsg_type == RTM_NEWROUTE || header->nlmsg_type == RTM_DELROUTE ||
            header->nlmsg_type == NLMSG_OVERRUN) {
            return true;
        }
        const auto message_size = static_cast<std::size_t>(NLMSG_ALIGN(header->nlmsg_len));
        if (message_size > remaining) {
            break;
        }
        cursor += message_size;
        remaining -= message_size;
    }
    return false;
}

}  // namespace

int main() {
    const char* runtime_dir = std::getenv("XDG_RUNTIME_DIR");
    const char* home_dir = std::getenv("HOME");
    const std::filesystem::path state_dir = runtime_dir != nullptr
        ? std::filesystem::path{runtime_dir} / "dotfiles"
        : std::filesystem::path{home_dir != nullptr ? home_dir : "."} / ".cache/dotfiles";
    const auto state_file = state_dir / state_name;
    try {
        std::filesystem::create_directories(state_dir);
    } catch (const std::filesystem::filesystem_error& error) {
        std::cerr << "network-status-live: " << error.what() << '\n';
        return 1;
    }

    const UniqueFd inotify_fd{::inotify_init1(IN_CLOEXEC)};
    if (inotify_fd.get() < 0 ||
        ::inotify_add_watch(inotify_fd.get(), state_dir.c_str(),
                            IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM |
                                IN_CLOSE_WRITE | IN_ATTRIB) < 0) {
        std::cerr << "network-status-live: inotify: " << std::strerror(errno) << '\n';
        return 1;
    }

    const UniqueFd route_fd{::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_ROUTE)};
    if (route_fd.get() < 0) {
        std::cerr << "network-status-live: netlink socket: " << std::strerror(errno) << '\n';
        return 1;
    }
    sockaddr_nl address{};
    address.nl_family = AF_NETLINK;
    address.nl_groups = RTMGRP_LINK | RTMGRP_IPV4_IFADDR | RTMGRP_IPV4_ROUTE;
    if (::bind(route_fd.get(), reinterpret_cast<const sockaddr*>(&address), sizeof(address)) < 0) {
        std::cerr << "network-status-live: netlink bind: " << std::strerror(errno) << '\n';
        return 1;
    }

    std::string previous_status;
    const auto refresh = [&]() {
        try {
            const auto status = current_status(state_file);
            if (status != previous_status) {
                std::cout << status << '\n' << std::flush;
                previous_status = status;
            }
        } catch (const std::filesystem::filesystem_error& error) {
            std::cerr << "network-status-live: " << error.what() << '\n';
        }
    };
    refresh();

    std::array<pollfd, 2> descriptors{{
        {inotify_fd.get(), POLLIN, 0},
        {route_fd.get(), POLLIN, 0},
    }};
    alignas(std::max_align_t) std::array<char, 4096> buffer{};
    while (true) {
        const int result = ::poll(descriptors.data(), descriptors.size(), -1);
        if (result < 0) {
            if (errno == EINTR) {
                continue;
            }
            std::cerr << "network-status-live: poll: " << std::strerror(errno) << '\n';
            return 1;
        }

        bool should_refresh = false;
        if ((descriptors[0].revents & POLLIN) != 0) {
            const auto bytes = ::read(inotify_fd.get(), buffer.data(), buffer.size());
            if (bytes < 0 && errno != EINTR) {
                std::cerr << "network-status-live: inotify read: " << std::strerror(errno) << '\n';
                return 1;
            }
            if (bytes > 0) {
                auto* event = reinterpret_cast<const inotify_event*>(buffer.data());
                const auto* const end = buffer.data() + bytes;
                while (reinterpret_cast<const char*>(event) < end) {
                    if (event->len > 0 && state_name == event->name) {
                        should_refresh = true;
                    }
                    event = reinterpret_cast<const inotify_event*>(
                        reinterpret_cast<const char*>(event) + sizeof(inotify_event) + event->len);
                }
            }
        }
        if ((descriptors[1].revents & POLLIN) != 0) {
            const auto bytes = ::recv(route_fd.get(), buffer.data(), buffer.size(), 0);
            if (bytes < 0 && errno != EINTR) {
                std::cerr << "network-status-live: netlink read: " << std::strerror(errno) << '\n';
                return 1;
            }
            should_refresh = should_refresh ||
                (bytes > 0 && has_relevant_route_event(buffer.data(), static_cast<std::size_t>(bytes)));
        }
        if (should_refresh) {
            refresh();
        }
    }
}
