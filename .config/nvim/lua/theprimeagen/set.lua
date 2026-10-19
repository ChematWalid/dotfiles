vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

-- Allow switching buffers with unsaved changes in background
vim.opt.hidden = true

-- Debounce text-change autosaves so typing does not cause a disk write for
-- every edit. Keep immediate saves when leaving Insert mode or the editor.
local uv = vim.uv or vim.loop
local autosave_delay_ms = 500
local autosave_timers = {}
local autosave_generations = {}

local function cancel_autosave(buf)
    local timer = autosave_timers[buf]
    if timer then
        autosave_timers[buf] = nil
        autosave_generations[buf] = (autosave_generations[buf] or 0) + 1
        timer:stop()
        timer:close()
    end
end

local function save_buffer(buf)
    cancel_autosave(buf)
    if not vim.api.nvim_buf_is_valid(buf)
        or not vim.bo[buf].modified
        or vim.bo[buf].buftype ~= ""
        or vim.api.nvim_buf_get_name(buf) == ""
        or vim.bo[buf].filetype == "" then
        return
    end

    vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! write")
    end)
end

local function schedule_autosave(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local timer = autosave_timers[buf]
    autosave_generations[buf] = (autosave_generations[buf] or 0) + 1
    local generation = autosave_generations[buf]
    if not timer then
        timer = uv.new_timer()
        autosave_timers[buf] = timer
    else
        timer:stop()
    end

    timer:start(autosave_delay_ms, 0, vim.schedule_wrap(function()
        if autosave_timers[buf] ~= timer or autosave_generations[buf] ~= generation then
            return
        end
        autosave_timers[buf] = nil
        autosave_generations[buf] = generation + 1
        timer:close()
        save_buffer(buf)
    end))
end

local autosave_group = vim.api.nvim_create_augroup("UserAutoSave", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = autosave_group,
    callback = function(event)
        schedule_autosave(event.buf)
    end,
    desc = "Debounced autosave after editing",
})

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
    group = autosave_group,
    callback = function(event)
        save_buffer(event.buf)
    end,
    desc = "Save edited buffer when editing pauses or focus leaves Neovim",
})

vim.api.nvim_create_autocmd("BufWipeout", {
    group = autosave_group,
    callback = function(event)
        cancel_autosave(event.buf)
    end,
    desc = "Release pending autosave timer when a buffer closes",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    group = autosave_group,
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            save_buffer(buf)
        end
    end,
    desc = "Save pending edits before Neovim exits",
})

