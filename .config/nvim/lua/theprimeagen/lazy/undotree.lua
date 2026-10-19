return {
    "mbbill/undotree",
    cmd = {
        "UndotreeToggle",
        "UndotreeHide",
        "UndotreeShow",
        "UndotreeFocus",
        "UndotreePersistUndo",
    },
    keys = { "<leader>u" },
    config = function()
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
    end
}
