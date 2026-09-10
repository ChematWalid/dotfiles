return {
    "sphamba/smear-cursor.nvim",
    cond = function()
        -- Only enable in terminal Neovim (Neovide has its own native GPU cursor)
        return not vim.g.neovide and not vim.g.vscode
    end,
    opts = {
        cursor_color = "#cba6f7", -- Catppuccin Mocha Mauve
        stiffness = 0.85,         -- Snappy, responsive animation without lag
        trailing_stiffness = 0.6, -- Swift trail catch-up
        distance_stop_animating = 0.5,
        smear_between_buffers = true,
        smear_between_neighbor_lines = false, -- Eliminates choppiness on standard j/k line navigation
        scroll_buffer_space = true,
        legacy_computing_symbols_support = false,
    },
}
