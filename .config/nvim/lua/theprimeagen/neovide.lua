if vim.g.neovide then
    -- Font configuration (Fira Code)
    vim.o.guifont = "Fira Code:h14"

    -- Cursor animations & VFX
    vim.g.neovide_cursor_animation_length = 0.08
    vim.g.neovide_cursor_trail_size = 0.8
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_cursor_smooth_blink = true
    vim.g.neovide_cursor_vfx_mode = "railgun" -- Options: "railgun", "torpedo", "pixiedust", "sonicboom", "ripple", "wireframe", ""

    -- Smooth scrolling
    vim.g.neovide_scroll_animation_length = 0.3

    -- Transparency and window styling
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_normal_opacity = 0.95
    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0
    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 10
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5

    -- General behavior
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_confirm_quit = true
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_refresh_rate = 144

    -- Dynamic scaling helper
    local change_scale_factor = function(delta)
        vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1.0) * delta
    end

    -- Keymaps for scaling & window management
    vim.keymap.set({ "n", "v" }, "<C-=>", function() change_scale_factor(1.1) end, { desc = "Neovide: Zoom In" })
    vim.keymap.set({ "n", "v" }, "<C-+>", function() change_scale_factor(1.1) end, { desc = "Neovide: Zoom In" })
    vim.keymap.set({ "n", "v" }, "<C-->", function() change_scale_factor(0.9) end, { desc = "Neovide: Zoom Out" })
    vim.keymap.set({ "n", "v" }, "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end, { desc = "Neovide: Reset Zoom" })
    vim.keymap.set({ "n", "v" }, "<F11>", function() vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen end, { desc = "Neovide: Toggle Fullscreen" })

    -- Clipboard shortcuts
    vim.keymap.set("v", "<C-S-c>", '"+y', { desc = "Neovide: Copy to system clipboard" })
    vim.keymap.set({ "n", "v" }, "<C-S-v>", '"+P', { desc = "Neovide: Paste from system clipboard" })
    vim.keymap.set("i", "<C-S-v>", '<ESC>"+pa', { desc = "Neovide: Paste from system clipboard" })
    vim.keymap.set("c", "<C-S-v>", "<C-r>+", { desc = "Neovide: Paste from system clipboard" })
end
