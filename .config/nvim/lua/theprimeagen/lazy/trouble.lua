return {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = { "<leader>tt" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("trouble").setup({})
        vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>")
    end
}
