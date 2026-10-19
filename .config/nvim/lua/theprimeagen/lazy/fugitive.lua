return {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = { "<leader>gs" },
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
    end
}
