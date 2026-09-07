return {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
        mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
        hide_cursor = false, -- Keep cursor visible so it glides smoothly with smear-cursor
        stop_eof = true,     -- Stop at <EOF> when scrolling downwards
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
        easing = "quadratic", -- Smooth physics curve
        duration_multiplier = 0.7, -- Fast, responsive and buttery smooth
    },
}
