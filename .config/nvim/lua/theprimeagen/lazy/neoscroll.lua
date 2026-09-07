return {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    config = function()
        local neoscroll = require("neoscroll")
        neoscroll.setup({
            mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
            hide_cursor = false,
            stop_eof = true,
            respect_scrolloff = false,
            cursor_scrolls_alone = true,
            easing = "quadratic",
            duration_multiplier = 0.7,
        })

        -- Smooth mouse wheel scrolling
        vim.keymap.set({ "n", "v", "x" }, "<ScrollWheelUp>", function()
            neoscroll.scroll(-2, { move_cursor = false, duration = 80 })
        end, { desc = "Smooth Scroll Up" })

        vim.keymap.set({ "n", "v", "x" }, "<ScrollWheelDown>", function()
            neoscroll.scroll(2, { move_cursor = false, duration = 80 })
        end, { desc = "Smooth Scroll Down" })
    end,
}
