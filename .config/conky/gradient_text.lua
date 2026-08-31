require 'cairo'
require 'cairo_xlib'

local function hex_to_rgba(hex, alpha)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) / 255.0
    local g = tonumber(hex:sub(3, 4), 16) / 255.0
    local b = tonumber(hex:sub(5, 6), 16) / 255.0
    return r, g, b, (alpha or 1.0)
end

local function draw_gradient_text(cr, text, font_face, font_size, font_weight, x, y, align, angle_deg, color_stops, stroke_color, stroke_width, shadow_color, shadow_ox, shadow_oy)
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
        local sr, sg, sb, sa = hex_to_rgba(shadow_color, 0.9)
        cairo_set_source_rgba(cr, sr, sg, sb, sa)
        cairo_move_to(cr, draw_x + shadow_ox, draw_y + shadow_oy)
        cairo_text_path(cr, text)
        cairo_fill(cr)
    end

    -- 2. Stroke Border Pass (Sharp outline for 100% legibility on any wallpaper)
    if stroke_color and stroke_width and stroke_width > 0 then
        local kr, kg, kb, ka = hex_to_rgba(stroke_color, 1.0)
        cairo_set_source_rgba(cr, kr, kg, kb, ka)
        cairo_set_line_width(cr, stroke_width)
        cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
        cairo_move_to(cr, draw_x, draw_y)
        cairo_text_path(cr, text)
        cairo_stroke(cr)
    end

    -- 3. 45-Degree Diagonal Gradient Fill (Multi-stop Catppuccin Mocha)
    local angle_rad = angle_deg * math.pi / 180.0
    local cos_a = math.cos(angle_rad)
    local sin_a = math.sin(angle_rad)
    local x0 = draw_x + extents.x_bearing
    local y0 = draw_y + extents.y_bearing
    local w = extents.width
    local h = extents.height

    local pat = cairo_pattern_create_linear(x0, y0, x0 + w * cos_a, y0 + h * sin_a)
    for _, stop in ipairs(color_stops) do
        local r, g, b, a = hex_to_rgba(stop.hex, stop.alpha or 1.0)
        cairo_pattern_add_color_stop_rgba(pat, stop.offset, r, g, b, a)
    end

    cairo_set_source(cr, pat)
    cairo_move_to(cr, draw_x, draw_y)
    cairo_text_path(cr, text)
    cairo_fill(cr)

    cairo_pattern_destroy(pat)
end

function conky_gradient_overlay()
    if conky_window == nil then return end

    local ok, err = pcall(function()
        local cs = cairo_xlib_surface_create(
            conky_window.display,
            conky_window.drawable,
            conky_window.visual,
            conky_window.width,
            conky_window.height
        )
        local cr = cairo_create(cs)
        local center_x = conky_window.width / 2.0

        -- Option A: Clock Gradient (Mauve -> Pink -> Flamingo -> Rosewater at 45 deg)
        local clock_stops = {
            { offset = 0.00, hex = "#cba6f7" }, -- Mauve
            { offset = 0.33, hex = "#f5c2e7" }, -- Pink
            { offset = 0.66, hex = "#f2cdcd" }, -- Flamingo
            { offset = 1.00, hex = "#f5e0dc" }, -- Rosewater
        }

        -- Option A: Date & Music Gradient (Blue -> Sapphire -> Sky -> Green at 45 deg)
        local date_stops = {
            { offset = 0.00, hex = "#89b4fa" }, -- Blue
            { offset = 0.35, hex = "#74c7ec" }, -- Sapphire
            { offset = 0.70, hex = "#89dceb" }, -- Sky
            { offset = 1.00, hex = "#a6e3a1" }, -- Green
        }

        local time_text = conky_parse("${time %H:%M}")
        local date_text = conky_parse("${time %A, %B %d}")
        
        local music_text = ""
        local f = io.open("/tmp/conky-music.txt", "r")
        if f then
            music_text = f:read("*all") or ""
            f:close()
            music_text = music_text:gsub("^%s*(.-)%s*$", "%1")
        end

        -- 1. Clock (98pt Bold)
        draw_gradient_text(
            cr, time_text, "JetBrainsMono Nerd Font", 98, CAIRO_FONT_WEIGHT_BOLD,
            center_x, 120, "center", 45, clock_stops,
            "#11111b", 3.2, "#11111b", 3.5, 3.5
        )

        -- 2. Date (28pt Bold)
        draw_gradient_text(
            cr, date_text, "JetBrainsMono Nerd Font", 28, CAIRO_FONT_WEIGHT_BOLD,
            center_x, 195, "center", 45, date_stops,
            "#11111b", 2.4, "#11111b", 2.5, 2.5
        )

        -- 3. Now Playing (22pt Bold)
        if music_text ~= "" then
            draw_gradient_text(
                cr, music_text, "JetBrainsMono Nerd Font", 22, CAIRO_FONT_WEIGHT_BOLD,
                center_x, 260, "center", 45, date_stops,
                "#11111b", 2.4, "#11111b", 2.5, 2.5
            )
        end

        cairo_surface_flush(cs)
        cairo_destroy(cr)
        cairo_surface_destroy(cs)
    end)

    if not ok then
        io.stderr:write("Conky Cairo Gradient Error: " .. tostring(err) .. "\n")
    end
end
