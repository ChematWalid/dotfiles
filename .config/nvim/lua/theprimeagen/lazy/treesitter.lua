return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
        if not ok then
            ts_configs = require("nvim-treesitter.config")
        end
        ts_configs.setup({
            ensure_installed = {
                "c", "lua", "vim", "vimdoc", "query", "python", "javascript", "typescript", "tsx", "java", "html", "css", "json", "bash", "markdown", "markdown_inline", "rust", "go"
            },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        })
    end
}
