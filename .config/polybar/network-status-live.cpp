#include "include/event_utils.hpp"
#include "include/process.hpp"
#include "include/state_paths.hpp"
#include "include/unique_fd.hpp"

#include <array>
#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <filesystem>
#include <fstream>
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

using dotfiles::command_output;
using dotfiles::has_event;
using dotfiles::UniqueFd;

constexpr std::string_view state_name{"polybar-network-state"};
constexpr std::string_view disconnected{"󰤭 Disconnected"};

[[nodiscard]] std::string current_status(const std::filesystem::path& state_file) {
    std::error_code ec;
    if (std::filesystem::exists(state_file, ec) && !ec) {
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
        const auto address = (end == std::string::npos) ? route.substr(start) : route.substr(start, end - start);
        return address.empty() ? std::string{disconnected} : "󰤨 " + address;
    }

    char iwgetid[] = "iwgetid";
    char raw_ssid[] = "-r";
    char* arguments[]{iwgetid, raw_ssid, nullptr};
    const auto ssid = command_output(arguments);
    return ssid.empty() ? std::string{disconnected} : "󰤨 " + ssid;
}

[[nodiscard]] bool has_relevant_route_event(const char* buffer, std::size_t size) {
    std::size_t remaining = size;
    for (const auto* header = reinterpret_cast<const nlmsghdr*>(buffer);
         NLMSG_OK(header, remaining); header = NLMSG_NEXT(header, remaining)) {
        if (header->nlmsg_type == RTM_NEWLINK || header->nlmsg_type == RTM_DELLINK ||
            header->nlmsg_type == RTM_NEWADDR || header->nlmsg_type == RTM_DELADDR ||
            header->nlmsg_type == RTM_NEWROUTE || header->nlmsg_type == RTM_DELROUTE ||
            header->nlmsg_type == NLMSG_OVERRUN) {
            return true;
        }
    }
    return false;
}

}  // namespace

int main(int argc, char* argv[]) {
    const dotfiles::StatePaths paths = dotfiles::make_state_paths(state_name);
    if (argc > 1) {
        std::string_view arg{argv[1]};
        if (arg == "--toggle" || arg == "-t") {
            std::error_code ec;
            if (std::filesystem::exists(paths.file, ec)) {
                std::filesystem::remove(paths.file, ec);
            } else {
                std::ofstream out{paths.file};
                out << "1\n";
            }
            return 0;
        }
        if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: network-status-live [--toggle|-h|--help]\n";
            return 0;
        }
    }

    const std::filesystem::path state_dir = paths.directory;
    const std::filesystem::path state_file = paths.file;

    const UniqueFd inotify_fd{::inotify_init1(IN_CLOEXEC | IN_NONBLOCK)};
    if (inotify_fd.get() < 0 ||
        ::inotify_add_watch(inotify_fd.get(), state_dir.c_str(),
                            IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM |
                                IN_CLOSE_WRITE | IN_ATTRIB) < 0) {
        std::cerr << "network-status-live: inotify: " << std::strerror(errno) << '\n';
        return 1;
    }

    const UniqueFd route_fd{::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC | SOCK_NONBLOCK, NETLINK_ROUTE)};
    if (route_fd.get() < 0) {
        std::cerr << "network-status-live: netlink socket: " << std::strerror(errno) << '\n';
        return 1;
    }

    constexpr int rcvbuf_size = 128 * 1024;
    ::setsockopt(route_fd.get(), SOL_SOCKET, SO_RCVBUF, &rcvbuf_size, sizeof(rcvbuf_size));

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

    constexpr std::size_t netlink_buffer_size = std::size_t{64} * 1024U;
    alignas(nlmsghdr) std::array<char, netlink_buffer_size> netlink_buffer{};
    alignas(inotify_event) std::array<char, 4096> inotify_buffer{};

    while (true) {
        const int result = ::poll(descriptors.data(), descriptors.size(), -1);
        if (result < 0) {
            if (errno == EINTR) {
                continue;
            }
            std::cerr << "network-status-live: poll: " << std::strerror(errno) << '\n';
            return 1;
        }

        if (has_event(descriptors[0].revents, POLLERR | POLLHUP | POLLNVAL)) {
            std::cerr << "network-status-live: inotify error or hangup\n";
            return 1;
        }
        if (has_event(descriptors[1].revents, POLLERR | POLLHUP | POLLNVAL)) {
            std::cerr << "network-status-live: netlink error or hangup\n";
            return 1;
        }

        bool should_refresh = false;

        // Drain inotify events completely without blocking
        if (has_event(descriptors[0].revents, POLLIN)) {
            for (;;) {
                const auto bytes = ::read(inotify_fd.get(), inotify_buffer.data(), inotify_buffer.size());
                if (bytes < 0) {
                    if (errno == EINTR) {
                        continue;
                    }
                    if (errno == EAGAIN || errno == EWOULDBLOCK) {
                        break;
                    }
                    std::cerr << "network-status-live: inotify read: " << std::strerror(errno) << '\n';
                    return 1;
                }
                if (bytes == 0) {
                    break;
                }

                std::size_t offset = 0;
                const auto total_bytes = static_cast<std::size_t>(bytes);
                while (offset + sizeof(inotify_event) <= total_bytes) {
                    const auto* event = reinterpret_cast<const inotify_event*>(inotify_buffer.data() + offset);
                    const std::size_t event_size = sizeof(inotify_event) + event->len;
                    if (offset + event_size > total_bytes) {
                        break;
                    }
                    if (event->len > 0) {
                        const std::size_t name_len = ::strnlen(event->name, event->len);
                        if (state_name == std::string_view{event->name, name_len}) {
                            should_refresh = true;
                        }
                    }
                    offset += event_size;
                }
            }
        }

        // Drain netlink events completely without blocking
        if (has_event(descriptors[1].revents, POLLIN)) {
            for (;;) {
                const auto bytes = ::recv(route_fd.get(), netlink_buffer.data(), netlink_buffer.size(), 0);
                if (bytes < 0) {
                    if (errno == EINTR) {
                        continue;
                    }
                    if (errno == EAGAIN || errno == EWOULDBLOCK) {
                        break;
                    }
                    if (errno == ENOBUFS) {
                        // Kernel dropped netlink messages due to buffer overrun; refresh state and recover
                        should_refresh = true;
                        break;
                    }
                    std::cerr << "network-status-live: netlink read: " << std::strerror(errno) << '\n';
                    return 1;
                }
                if (bytes == 0) {
                    break;
                }
                if (has_relevant_route_event(netlink_buffer.data(), static_cast<std::size_t>(bytes))) {
                    should_refresh = true;
                }
            }
        }

        if (should_refresh) {
            refresh();
        }
    }
}
