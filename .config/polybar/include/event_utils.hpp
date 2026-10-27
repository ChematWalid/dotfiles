#pragma once

namespace dotfiles {

[[nodiscard]] constexpr bool has_event(short events, short event) noexcept {
    return (static_cast<unsigned short>(events) & static_cast<unsigned short>(event)) != 0;
}

} // namespace dotfiles
