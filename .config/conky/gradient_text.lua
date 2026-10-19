require 'cairo'
require 'cairo_xlib'

local function hex_to_rgba(hex, alpha)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) / 255.0
    local g = tonumber(hex:sub(3, 4), 16) / 255.0
    local b = tonumber(hex:sub(5, 6), 16) / 255.0
    return r, g, b, (alpha or 1.0)
end

local function make_color(hex, alpha)
    local r, g, b, a = hex_to_rgba(hex, alpha)
    return { r = r, g = g, b = b, a = a }
end

local function make_color_stop(offset, hex)
    local color = make_color(hex)
    color.offset = offset
    return color
end

local clock_stops = {
    make_color_stop(0.00, "#cba6f7"),
    make_color_stop(0.33, "#f5c2e7"),
    make_color_stop(0.66, "#f2cdcd"),
    make_color_stop(1.00, "#f5e0dc"),
}

local date_stops = {
    make_color_stop(0.00, "#89b4fa"),
    make_color_stop(0.35, "#74c7ec"),
    make_color_stop(0.70, "#89dceb"),
    make_color_stop(1.00, "#a6e3a1"),
}

local shadow_color = make_color("#11111b", 0.9)
local stroke_color = make_color("#11111b", 1.0)
local gradient_cos_45 = math.cos(math.pi / 4.0)
local gradient_sin_45 = math.sin(math.pi / 4.0)

local home = os.getenv("HOME") or "."
local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or (home .. "/.cache")
local music_path = runtime_dir .. "/conky-music.txt"
local function draw_gradient_text(cr, text, font_face, font_size, font_weight, x, y, align, color_stops, stroke_width, shadow_ox, shadow_oy)
    if not text or text == "" then return end

    cairo_select_font_face(cr, font_face, CAIRO_FONT_SLANT_NORMAL, font_weight)
    cairo_set_font_size(cr, font_size)

    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    local draw_x = x
    if align == "center" then
        draw_x = x - (extents.width / 2.0 + extents.x_bearing)
    elseif align == "right" then
        draw_x = x - (extents.width + extents.x_bearing)
    end
    local draw_y = y

    -- 1. Drop Shadow Pass (Deep #11111b at 90% opacity)
    if shadow_color then
        cairo_set_source_rgba(cr, shadow_color.r, shadow_color.g, shadow_color.b, shadow_color.a)
        cairo_move_to(cr, draw_x + shadow_ox, draw_y + shadow_oy)
        cairo_text_path(cr, text)
        cairo_fill(cr)
    end

    -- 2. Stroke Border Pass (Sharp outline for 100% legibility on any wallpaper)
    if stroke_color and stroke_width and stroke_width > 0 then
        cairo_set_source_rgba(cr, stroke_color.r, stroke_color.g, stroke_color.b, stroke_color.a)
        cairo_set_line_width(cr, stroke_width)
        cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
        cairo_move_to(cr, draw_x, draw_y)
        cairo_text_path(cr, text)
        cairo_stroke(cr)
    end

    -- 3. 45-Degree Diagonal Gradient Fill (Multi-stop Catppuccin Mocha)
    local x0 = draw_x + extents.x_bearing
    local y0 = draw_y + extents.y_bearing
    local w = extents.width
    local h = extents.height

    local pat = cairo_pattern_create_linear(x0, y0, x0 + w * gradient_cos_45, y0 + h * gradient_sin_45)
    for i = 1, #color_stops do
        local stop = color_stops[i]
        cairo_pattern_add_color_stop_rgba(pat, stop.offset, stop.r, stop.g, stop.b, stop.a)
    end

    cairo_set_source(cr, pat)
    cairo_move_to(cr, draw_x, draw_y)
    cairo_text_path(cr, text)
    cairo_fill(cr)

    cairo_pattern_destroy(pat)
end

function conky_gradient_overlay()
    if conky_window == nil then return end

    local time_text = conky_parse("${time %H:%M}")
    local date_text = conky_parse("${time %A, %B %d}")
    local music_text = ""
    local f = io.open(music_path, "r")
    if f then
        music_text = f:read("*all") or ""
        f:close()
        music_text = music_text:gsub("^%s*(.-)%s*$", "%1")
    end

    local ok, err = pcall(function()
        -- Use Conky's active draw buffer so Cairo output participates in
        -- double-buffer presentation instead of writing around it.
        local cs = conky_surface()
        if not cs then return end
        local cr = cairo_create(cs)

        local center_x = conky_window.width / 2.0

        -- 1. Clock (98pt Bold)
        draw_gradient_text(
            cr, time_text, "JetBrainsMono Nerd Font", 98, CAIRO_FONT_WEIGHT_BOLD,
            center_x, 120, "center", clock_stops,
            3.2, 3.5, 3.5
        )

        -- 2. Date (28pt Bold)
        draw_gradient_text(
            cr, date_text, "JetBrainsMono Nerd Font", 28, CAIRO_FONT_WEIGHT_BOLD,
            center_x, 195, "center", date_stops,
            2.4, 2.5, 2.5
        )

        -- 3. Now Playing (22pt Bold)
        if music_text ~= "" then
            draw_gradient_text(
                cr, music_text, "JetBrainsMono Nerd Font", 22, CAIRO_FONT_WEIGHT_BOLD,
                center_x, 260, "center", date_stops,
                2.4, 2.5, 2.5
            )
        end

        cairo_surface_flush(cs)
        cairo_destroy(cr)
    end)

    if not ok then
        io.stderr:write("Conky Cairo Gradient Error: " .. tostring(err) .. "\n")
    end
end
