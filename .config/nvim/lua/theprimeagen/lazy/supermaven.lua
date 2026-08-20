return {
    "supermaven-inc/supermaven-nvim",
    config = function()
        require("supermaven-nvim").setup({
            keymaps = {
                accept_suggestion = "<C-f>",
                clear_suggestion = "<C-]>",
                accept_word = "<C-j>",
            },
            color = {
                suggestion_color = "#6c7086",
                cterm = 244,
            },
            disable_inline_completion = false,
            disable_keymaps = false,
        })
    end,
}
