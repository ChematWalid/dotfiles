#include <array>
#include <cerrno>
#include <cstring>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <system_error>

#include <arpa/inet.h>
#include <ifaddrs.h>
#include <linux/if_addr.h>
#include <linux/if_link.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <net/if.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

namespace {

constexpr std::size_t receive_buffer_size = std::size_t{64} * 1024U;

[[nodiscard]] std::string detect_default_interface() {
    struct ifaddrs* ifaddr = nullptr;
    if (::getifaddrs(&ifaddr) == -1) {
        return "eth0";
    }
    std::string candidate;
    for (struct ifaddrs* ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
        if (!ifa->ifa_name) continue;
        std::string_view name{ifa->ifa_name};
        if (name == "lo" || name.rfind("wl", 0) == 0 || name.rfind("docker", 0) == 0 ||
            name.rfind("br-", 0) == 0 || name.rfind("veth", 0) == 0 ||
            name.rfind("tailscale", 0) == 0 || name.rfind("tun", 0) == 0 ||
            name.rfind("tap", 0) == 0) {
            continue;
        }
        if (name.rfind("en", 0) == 0 || name.rfind("eth", 0) == 0) {
            candidate = ifa->ifa_name;
            break;
        }
        if (candidate.empty()) {
            candidate = ifa->ifa_name;
        }
    }
    ::freeifaddrs(ifaddr);
    return candidate.empty() ? "eth0" : candidate;
}

[[nodiscard]] constexpr bool has_event(short events, short event) noexcept {
    return (static_cast<unsigned short>(events) & static_cast<unsigned short>(event)) != 0;
}

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

[[nodiscard]] bool is_target_link_event(const nlmsghdr* header,
                                        std::string_view interface_name,
                                        unsigned int interface_index) {
    if (header->nlmsg_type != RTM_NEWLINK && header->nlmsg_type != RTM_DELLINK) {
        return false;
    }
    if (header->nlmsg_len < NLMSG_LENGTH(sizeof(ifinfomsg))) {
        return false;
    }

    const auto* info = reinterpret_cast<const ifinfomsg*>(NLMSG_DATA(header));
    if (interface_index != 0 && static_cast<unsigned int>(info->ifi_index) == interface_index) {
        return true;
    }

    const char* cursor = reinterpret_cast<const char*>(IFLA_RTA(info));
    std::size_t remaining = static_cast<std::size_t>(IFLA_PAYLOAD(header));
    while (remaining >= sizeof(rtattr)) {
        const auto* attribute = reinterpret_cast<const rtattr*>(cursor);
        if (attribute->rta_len < sizeof(rtattr) || attribute->rta_len > remaining) {
            break;
        }
        if (attribute->rta_type == IFLA_IFNAME) {
            const auto* name = static_cast<const char*>(RTA_DATA(attribute));
            const auto name_size = strnlen(name, static_cast<std::size_t>(RTA_PAYLOAD(attribute)));
            return std::string_view{name, name_size} == interface_name;
        }
        const auto attribute_size = static_cast<std::size_t>(RTA_ALIGN(attribute->rta_len));
        if (attribute_size > remaining) {
            break;
        }
        cursor += attribute_size;
        remaining -= attribute_size;
    }
    return false;
}

[[nodiscard]] bool is_target_event(const nlmsghdr* header,
                                   std::string_view interface_name,
                                   unsigned int interface_index) {
    if (header->nlmsg_type == RTM_NEWLINK || header->nlmsg_type == RTM_DELLINK) {
        return is_target_link_event(header, interface_name, interface_index);
    }

    if (header->nlmsg_type == RTM_NEWADDR || header->nlmsg_type == RTM_DELADDR) {
        if (header->nlmsg_len < NLMSG_LENGTH(sizeof(ifaddrmsg))) {
            return false;
        }
        const auto* info = reinterpret_cast<const ifaddrmsg*>(NLMSG_DATA(header));
        if (interface_index == 0) {
            const std::string name_str{interface_name};
            interface_index = ::if_nametoindex(name_str.c_str());
        }
        return interface_index != 0 && static_cast<unsigned int>(info->ifa_index) == interface_index;
    }

    return header->nlmsg_type == NLMSG_OVERRUN;
}

[[nodiscard]] std::string current_status(const std::string& interface_name) {
    ifaddrs* raw_addresses = nullptr;
    if (::getifaddrs(&raw_addresses) != 0) {
        throw std::system_error(errno, std::generic_category(), "getifaddrs");
    }
    const std::unique_ptr<ifaddrs, decltype(&::freeifaddrs)> addresses{
        raw_addresses, &::freeifaddrs};

    constexpr unsigned int required_flags = IFF_UP | IFF_RUNNING;
    for (const auto* address = addresses.get(); address != nullptr; address = address->ifa_next) {
        if (address->ifa_name == nullptr || interface_name != address->ifa_name ||
            address->ifa_addr == nullptr ||
            (address->ifa_flags & required_flags) != required_flags ||
            address->ifa_addr->sa_family != AF_INET) {
            continue;
        }

        std::array<char, INET_ADDRSTRLEN> ip{};
        const auto* ipv4 = reinterpret_cast<const sockaddr_in*>(address->ifa_addr);
        if (::inet_ntop(AF_INET, &ipv4->sin_addr, ip.data(), ip.size()) == nullptr) {
            throw std::system_error(errno, std::generic_category(), "inet_ntop");
        }
        return "󰈀 " + std::string{ip.data()};
    }
    return {};
}

void print_if_changed(const std::string& interface_name, std::string& previous_status) {
    try {
        auto status = current_status(interface_name);
        if (status != previous_status) {
            std::cout << status << '\n' << std::flush;
            previous_status = std::move(status);
        }
    } catch (const std::system_error& error) {
        std::cerr << "network-eth-live: " << error.what() << '\n';
    }
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc > 2) {
        std::cerr << "Usage: network-eth-live [interface]\n";
        return 2;
    }

    std::string interface_name;
    if (argc == 2) {
        interface_name = argv[1];
    } else {
        interface_name = detect_default_interface();
    }

    unsigned int interface_index = ::if_nametoindex(interface_name.c_str());
    if (interface_index == 0 && argc == 2) {
        interface_name = detect_default_interface();
        interface_index = ::if_nametoindex(interface_name.c_str());
    }

    UniqueFd netlink_socket{::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC | SOCK_NONBLOCK, NETLINK_ROUTE)};
    if (netlink_socket.get() < 0) {
        std::cerr << "network-eth-live: socket: " << std::strerror(errno) << '\n';
        return 1;
    }

    constexpr int rcvbuf_size = 128 * 1024;
    ::setsockopt(netlink_socket.get(), SOL_SOCKET, SO_RCVBUF, &rcvbuf_size, sizeof(rcvbuf_size));

    sockaddr_nl local_address{};
    local_address.nl_family = AF_NETLINK;
    local_address.nl_groups = RTMGRP_LINK | RTMGRP_IPV4_IFADDR;
    if (::bind(netlink_socket.get(), reinterpret_cast<const sockaddr*>(&local_address),
               sizeof(local_address)) != 0) {
        std::cerr << "network-eth-live: bind: " << std::strerror(errno) << '\n';
        return 1;
    }

    std::string previous_status;
    print_if_changed(interface_name, previous_status);

    pollfd descriptor{netlink_socket.get(), POLLIN, 0};
    alignas(nlmsghdr) std::array<char, receive_buffer_size> buffer{};

    while (true) {
        const int result = ::poll(&descriptor, 1, -1);
        if (result < 0) {
            if (errno == EINTR) {
                continue;
            }
            std::cerr << "network-eth-live: poll: " << std::strerror(errno) << '\n';
            return 1;
        }

        if (has_event(descriptor.revents, POLLERR | POLLHUP | POLLNVAL)) {
            std::cerr << "network-eth-live: netlink error or hangup\n";
            return 1;
        }

        if (!has_event(descriptor.revents, POLLIN)) {
            continue;
        }

        bool refresh = false;
        for (;;) {
            const auto received = ::recv(netlink_socket.get(), buffer.data(), buffer.size(), 0);
            if (received < 0) {
                if (errno == EINTR) {
                    continue;
                }
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    break;
                }
                if (errno == ENOBUFS) {
                    // Buffer overrun: kernel dropped messages. Refresh state and continue.
                    refresh = true;
                    break;
                }
                std::cerr << "network-eth-live: recv: " << std::strerror(errno) << '\n';
                return 1;
            }
            if (received == 0) {
                return 0; // EOF on netlink socket
            }

            std::size_t remaining = static_cast<std::size_t>(received);
            for (auto* header = reinterpret_cast<nlmsghdr*>(buffer.data());
                 NLMSG_OK(header, remaining); header = NLMSG_NEXT(header, remaining)) {
                if (is_target_event(header, interface_name, interface_index)) {
                    refresh = true;
                }
            }
        }

        if (refresh) {
            interface_index = ::if_nametoindex(interface_name.c_str());
            print_if_changed(interface_name, previous_status);
        }
    }
}
