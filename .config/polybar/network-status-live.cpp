#include <array>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <poll.h>
#include <string>
#include <string_view>
#include <system_error>

#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <sys/inotify.h>
#include <sys/socket.h>
#include <unistd.h>

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

[[nodiscard]] std::string command_output(const char* command) {
    FILE* raw_pipe = ::popen(command, "r");
    if (raw_pipe == nullptr) {
        return {};
    }
    std::string output;
    std::array<char, 256> buffer{};
    while (std::fgets(buffer.data(), static_cast<int>(buffer.size()), raw_pipe) != nullptr) {
        output.append(buffer.data());
    }
    (void)::pclose(raw_pipe);
    while (!output.empty() && (output.back() == '\n' || output.back() == '\r')) {
        output.pop_back();
    }
    return output;
}

[[nodiscard]] std::string current_status(const std::filesystem::path& state_file) {
    if (std::filesystem::exists(state_file)) {
        const auto route = command_output("ip -4 route get 1.1.1.1 2>/dev/null");
        const auto source = route.find(" src ");
        if (source == std::string::npos) {
            return std::string{disconnected};
        }
        const auto start = source + 5;
        const auto end = route.find(' ', start);
        const auto address = route.substr(start, end - start);
        return address.empty() ? std::string{disconnected} : "󰤨 " + address;
    }

    const auto ssid = command_output("iwgetid -r 2>/dev/null");
    return ssid.empty() ? std::string{disconnected} : "󰤨 " + ssid;
}

[[nodiscard]] bool has_relevant_route_event(const char* buffer, std::size_t size) {
    auto* header = reinterpret_cast<const nlmsghdr*>(buffer);
    auto remaining = static_cast<int>(size);
    while (NLMSG_OK(header, remaining)) {
        if (header->nlmsg_type == RTM_NEWLINK || header->nlmsg_type == RTM_DELLINK ||
            header->nlmsg_type == RTM_NEWADDR || header->nlmsg_type == RTM_DELADDR ||
            header->nlmsg_type == RTM_NEWROUTE || header->nlmsg_type == RTM_DELROUTE ||
            header->nlmsg_type == NLMSG_OVERRUN) {
            return true;
        }
        header = NLMSG_NEXT(header, remaining);
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
    std::array<char, 4096> buffer{};
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
