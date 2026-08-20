vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move visual selection up/down (Primeagen style)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor in place on J
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor centered on scrolling and search
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste over selection without losing register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- System clipboard yank
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete into void register
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

-- Disable Q
vim.keymap.set("n", "Q", "<nop>")

-- Format buffer via LSP
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- Quick substitute for word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
