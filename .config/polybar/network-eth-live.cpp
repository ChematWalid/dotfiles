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
#include <sys/socket.h>
#include <unistd.h>

namespace {

constexpr std::string_view default_interface = "enp4s0";
constexpr std::size_t receive_buffer_size = std::size_t{64} * 1024U;

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

    const auto* info = reinterpret_cast<const ifinfomsg*>(NLMSG_DATA(header));
    if (static_cast<unsigned int>(info->ifi_index) == interface_index) {
        return true;
    }

    int remaining = static_cast<int>(IFLA_PAYLOAD(header));
    for (auto* attribute = IFLA_RTA(info); RTA_OK(attribute, remaining);
         attribute = RTA_NEXT(attribute, remaining)) {
        if (attribute->rta_type == IFLA_IFNAME) {
            const auto* name = static_cast<const char*>(RTA_DATA(attribute));
            const auto name_size = strnlen(name, RTA_PAYLOAD(attribute));
            return std::string_view{name, name_size} == interface_name;
        }
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
        const auto* info = reinterpret_cast<const ifaddrmsg*>(NLMSG_DATA(header));
        return info->ifa_index == interface_index;
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

    const std::string interface_name =
        argc == 2 ? std::string{argv[1]} : std::string{default_interface};
    unsigned int interface_index = ::if_nametoindex(interface_name.c_str());

    UniqueFd netlink_socket{::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_ROUTE)};
    if (netlink_socket.get() < 0) {
        std::cerr << "network-eth-live: socket: " << std::strerror(errno) << '\n';
        return 1;
    }

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

    alignas(nlmsghdr) std::array<char, receive_buffer_size> buffer{};
    while (true) {
        const auto received = ::recv(netlink_socket.get(), buffer.data(), buffer.size(), 0);
        if (received < 0) {
            if (errno == EINTR) {
                continue;
            }
            std::cerr << "network-eth-live: recv: " << std::strerror(errno) << '\n';
            return 1;
        }

        bool refresh = false;
        int remaining = static_cast<int>(received);
        for (auto* header = reinterpret_cast<nlmsghdr*>(buffer.data());
             NLMSG_OK(header, remaining); header = NLMSG_NEXT(header, remaining)) {
            if (is_target_event(header, interface_name, interface_index)) {
                refresh = true;
                break;
            }
        }

        if (refresh) {
            interface_index = ::if_nametoindex(interface_name.c_str());
            print_if_changed(interface_name, previous_status);
        }
    }
}
