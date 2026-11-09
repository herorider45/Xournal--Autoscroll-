-- XournalAutoScroll
-- Mouse-position-driven autoscroll for Xournal++ on X11.
--
-- Toggle with "g" by default.
-- Move the pointer away from the position where autoscroll was enabled:
--   down/right = scroll down/right
--   up/left    = scroll up/left

local LuaGObject = require("LuaGObject")
local Gdk = LuaGObject.require("Gdk", "3.0")
local GLib = LuaGObject.require("GLib", "2.0")
local Gtk = LuaGObject.require("Gtk", "3.0") -- gtk object to generate the autoscroll icon

-- Tuning parameters
local INTERVAL_MS = 16       
local DEADZONE_PX = 2        -- ignore small pointer movements
local SPEED_GAIN = 20.0      -- scroll px/s per pointer px beyond deadzone
local MAX_SPEED = 20000      -- maximum scroll speed, in px/s

-- path with flatpak version of xournal++:
local ICON_PATH = "/home/tony/.var/app/com.github.xournalpp.xournalpp/config/xournalpp/icons/autoscroll-icon.svg"

local enabled = false
local timer_id = nil
local pointer = nil
local anchor_x = 0
local anchor_y = 0
local last_tick_us = 0

-- Window that will contain the icon
local icon_window = nil

local function get_pointer()
    local display = Gdk.Display.get_default()
    assert(display, "No GDK display available")

    local seat = display:get_default_seat()
    assert(seat, "No GDK seat available")

    local device = seat:get_pointer()
    assert(device, "Could not access the mouse pointer")
    return device
end

local function pointer_position(device)
    -- On X11 GDK returns the screen and global pointer coordinates.
    local screen, x, y = pointer:get_position_double()
    assert(x ~= nil and y ~= nil, "Could not read pointer coordinates")
    return x, y
end

local function apply_deadzone(value)
    local magnitude = math.abs(value)
    if magnitude <= DEADZONE_PX then
        return 0
    end
    return (value < 0 and -1 or 1) * (magnitude - DEADZONE_PX)
end

local function clamp(value, limit)
    if value > limit then return limit end
    if value < -limit then return -limit end
    return value
end

local function hide_anchor_icon()
    if icon_window then
        icon_window:destroy()
        icon_window = nil
    end
end

local function show_anchor_icon(x, y)
    hide_anchor_icon()

    -- Popup window
    icon_window = Gtk.Window.new(Gtk.WindowType.POPUP)
    icon_window:set_accept_focus(false) -- avoid grabbing focus by the icon window

    -- Get a transparent background
    local screen = icon_window:get_screen()
    local visual = screen:get_rgba_visual()
    if visual then
        icon_window:set_visual(visual)
        icon_window:set_app_paintable(true)
    end

    -- Apply the css
    pcall(function()
        local provider = Gtk.CssProvider.new()
        provider:load_from_data("window { background-color: transparent; }")
        local context = icon_window:get_style_context()
        context:add_provider(provider, 600) -- 600 = Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    end)

    -- Upload the image from the .svg path
    local image = Gtk.Image.new_from_file(ICON_PATH)
    icon_window:add(image)

    -- Center the icon on the cursor
    local offset_x = 16
    local offset_y = 16
    icon_window:move(x - offset_x, y - offset_y)

    icon_window:show_all()
end

local function stop_autoscroll()
    enabled = false
    if timer_id ~= nil then
        GLib.source_remove(timer_id)
        timer_id = nil
    end
    pointer = nil
    hide_anchor_icon()
    print("[XournalAutoScroll] OFF")
end

local function tick()
    if not enabled then
        timer_id = nil
        return false
    end

    local ok, x, y = pcall(pointer_position, pointer)
    if not ok then
        print("[XournalAutoScroll] Pointer read failed: " .. tostring(x))
        timer_id = nil
        enabled = false
        pointer = nil
        hide_anchor_icon()
        return false
    end

    local dx = apply_deadzone(x - anchor_x)
    local dy = apply_deadzone(y - anchor_y)

    local now_us = GLib.get_monotonic_time()
    local dt = (now_us - last_tick_us) / 1000000.0
    last_tick_us = now_us

    -- Avoid a large jump if the application was briefly busy.
    dt = math.min(math.max(dt, 0), 0.05)

    local vx = clamp(dx * SPEED_GAIN, MAX_SPEED)
    local vy = clamp(dy * SPEED_GAIN, MAX_SPEED)

    if vx ~= 0 or vy ~= 0 then
        local scroll_ok, err = pcall(app.scrollToPos, vx * dt, vy * dt, true)
        if not scroll_ok then
            print("[XournalAutoScroll] Scroll failed: " .. tostring(err))
            timer_id = nil
            enabled = false
            pointer = nil
            hide_anchor_icon()
            return false
        end
    end

    return true
end

function toggleAutoScroll()
    if enabled then
        stop_autoscroll()
        return
    end

    local ok, device_or_error = pcall(get_pointer)
    if not ok then
        app.openDialog(
            "XournalAutoScroll: cannot access the X11 pointer.\n" .. tostring(device_or_error),
            {"OK"},
            "",
            true
        )
        return
    end

    pointer = device_or_error

    local pos_ok, x, y = pcall(pointer_position, pointer)
    if not pos_ok then
        pointer = nil
        app.openDialog(
            "XournalAutoScroll: cannot read the pointer position.\n" .. tostring(x),
            {"OK"},
            "",
            true
        )
        return
    end

    anchor_x = x
    anchor_y = y
    last_tick_us = GLib.get_monotonic_time()
    enabled = true
    
    show_anchor_icon(x, y)

    timer_id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, INTERVAL_MS, tick)
    print("[XournalAutoScroll] ON — move the pointer away from the activation point; press g to stop")
end

-- initializing the function

function initUi()

    app.registerUi({
        menu = "Toggle AutoScroll",
        callback = "toggleAutoScroll",
        accelerator = "g"            -- edit the shortcut here
    })
    
end













