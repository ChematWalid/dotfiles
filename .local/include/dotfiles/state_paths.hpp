#pragma once

#include <cstdlib>
#include <filesystem>
#include <string>
#include <string_view>
#include <system_error>

namespace dotfiles {

struct StatePaths {
    std::string directory;
    std::string file;
};

/// Resolves standard runtime directory and target state file under dotfiles namespace.
inline StatePaths make_state_paths(std::string_view state_filename) {
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
    return paths;
}

} // namespace dotfiles
