-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- extra libraries
local vicious = require("vicious")
local lfs = require("lfs")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
home = os.getenv("HOME")
beautiful.init(home .. "/.config/awesome/theme/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ "1", "2", "3", "4", "5", "6" }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   -- { "manual", terminal .. " -e man awesome" },
   -- { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

systemmenu = {
    { "suspend", "systemctl suspend" },
    { "reboot", "systemctl reboot" },
    { "shutdown", "systemctl poweroff"},
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "system", systemmenu},
                                    -- { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)) / 256, tonumber("0x"..hex:sub(3,4)) / 256, tonumber("0x"..hex:sub(5,6)) / 256}
end

arrowcache = {}

-- {{{ Function to create a new arrow image on the fly
function create_arrow(bgcolor, arrowcolor, direction)
    local cachestr = bgcolor .. arrowcolor .. direction
    if arrowcache[cachestr] ~= nil then
        return arrowcache[cachestr]
    end

    local arrow = wibox.widget.base.make_widget()
    arrow.bgcolor = hex2rgb(bgcolor)
    arrow.arrowcolor = hex2rgb(arrowcolor)

    arrow.fit = function(arrow, width, height)
        local size = math.min(width, height)
        return size, size
    end

    local ab, c
    if direction == "left" then
        ab = 0.75
        c = 0.25
    elseif direction == "right" then
        ab = 0.25
        c = 0.75
    else
        error("invalid arrow direction '".. direction .."'")
    end

    arrow.draw = function(arrow, wibox, cr, width, height)
        -- fill out the background
        cr:rectangle(0, 0, width, height)
        cr:set_source_rgb(unpack(arrow.bgcolor))
        cr:fill()

        -- draw the arrow itself
        cr:move_to(width, 0)
        cr:line_to(width * ab, 0)
        cr:line_to(width * c, height / 2)
        cr:line_to(width * ab, height)
        cr:line_to(width, height)
        cr:close_path()
        cr:set_source_rgb(unpack(arrow.arrowcolor))
        cr:fill()
    end

    arrowcache[cachestr] = arrow
    return arrow
end
-- }}}

-- {{{ Function to create a new titlebar image
function create_titlebar_image(bgcolor, textcolor, text)
    local img = wibox.widget.base.make_widget()
    img.bgcolor = hex2rgb(bgcolor)
    img.textcolor = hex2rgb(textcolor)
    img.text = text

    img.fit = function(img, width, height)
        local size = math.min(width, height)
        return size, size
    end

    img.draw = function(img, wibox, cr, width, height)
        -- fill out the background
        cr:rectangle(0, 0, width, height)
        cr:set_source_rgb(unpack(img.bgcolor))
        cr:fill()

        -- write the text
        cr:set_source_rgb(unpack(img.textcolor))
        cr:select_font_face("Terminus", 0, 0)
        cr:set_font_size(20)

        local extent = cr:text_extents(img.text)

        cr:move_to(width/2 - extent.width/2, height/2 + extent.height/2)
        cr:show_text(img.text)
    end

    return img
end
-- }}}


-- Create the date and time widget
datewidget = wibox.widget.background()
datewidget_text = wibox.widget.textbox()
datewidget:set_widget(datewidget_text)
datewidget:set_bg(beautiful.pl_1)

local datewidget_fmt = '<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">%a, %b %d %H:%M</span>'
vicious.register(datewidget_text, vicious.widgets.date, datewidget_fmt, 5)

-- Create the cpu usage widget
cpuwidget = wibox.widget.background()
cpuwidget_text = wibox.widget.textbox()
cpuwidget:set_widget(cpuwidget_text)
cpuwidget:set_bg(beautiful.pl_2)

local cpuwidget_fmt = '<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">CPU: $1%</span>'
vicious.register(cpuwidget_text, vicious.widgets.cpu, cpuwidget_fmt, 3)

-- Create the memory usage widget
memwidget = wibox.widget.background()
memwidget_text = wibox.widget.textbox()
memwidget:set_widget(memwidget_text)
memwidget:set_bg(beautiful.pl_3)

local memwidget_fmt = '<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">MEM: $1%</span>'
vicious.register(memwidget_text, vicious.widgets.mem, memwidget_fmt, 13)

-- Create the audio volume widget
volwidget = wibox.widget.background()
volwidget_text = wibox.widget.textbox()
volwidget:set_widget(volwidget_text)
volwidget:set_bg(beautiful.pl_4)

local volwidget_fmt = '<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">VOL: $1%</span>'
vicious.register(volwidget_text, vicious.widgets.volume, volwidget_fmt, 19, "Master", 5)

-- Create the spofity widget
spotifywidget = wibox.widget.background()
spotifywidget_text = wibox.widget.textbox()
spotifywidget_text:set_markup('<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">SPO: N/A - N/A</span>')
spotifywidget:set_widget(spotifywidget_text)
spotifywidget:set_bg(beautiful.pl_5)

spotify = {}
spotify.playback = false
spotify.title = "N/A"
spotify.artist = "N/A"

spotifywidget_update = function(event, interface, data)
    if data["PlaybackStatus"] then
        spotify.playback = data["PlaybackStatus"] == "Playing" and true or false
    elseif data["Metadata"] then
        spotify.title = data["Metadata"]["xesam:title"]

        artists = data["Metadata"]["xesam:artist"]
        for i=1,#artists do
            if i == 1 then
                spotify.artist = artists[i]
            else
                spotify.artist = spotify.artist .. ", " .. artists[i]
            end
        end
    end

    spotifywidget_text:set_markup('<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font ..'">SPO' .. (spotify.playback and '' or " (P)") .. ': '.. awful.util.escape(spotify.title) .. ' - ' .. awful.util.escape(spotify.artist) .. '</span>')
end

dbus.add_match("session", "type='signal',path='/org/mpris/MediaPlayer2',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'")
dbus.connect_signal("org.freedesktop.DBus.Properties", spotifywidget_update)

-- Activate slimlock on suspend/hibernate
prepare_for_sleep = function(...)
    local data = {...}
    if data[2] == true then
        awful.util.spawn("slimlock")
    end
end

dbus.add_match("system", "type='signal',path='/org/freedesktop/login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'")
dbus.connect_signal("org.freedesktop.login1.Manager", prepare_for_sleep)

-- Custom tasklist widget
function create_tasklistwidget()
    local tasklistwidget = wibox.layout.flex.horizontal()
    tasklistwidget.orig_add = tasklistwidget.add
    tasklistwidget.add = function(tasklist, widget)
        tasklistwidget:orig_add(create_arrow(beautiful.pl_2, beautiful.pl_1, "left"))
        tasklistwidget:orig_add(widget)
        tasklistwidget:orig_add(create_arrow(beautiful.pl_1, beautiful.pl_2, "left"))
    end
    return tasklistwidget
end

-- Batteru widget
batwidget = wibox.widget.background()
batwidget_text = wibox.widget.textbox()
batwidget:set_widget(batwidget_text)
batwidget:set_bg(beautiful.pl_5)

local batwidget_fmt = '<span color="' .. beautiful.pl_text .. '" font="' .. beautiful.pl_font .. '">BAT: $2% ($1$3)</span>'

-- {{{ Battery state
-- Initialize widget
vicious.register(batwidget_text, vicious.widgets.bat, batwidget_fmt, 61, "BAT0")

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons) --, nil, nil, create_tasklistwidget())

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    --right_layout:add(create_arrow(beautiful.bg_normal, beautiful.pl_6, "left"))
    right_layout:add(create_arrow(beautiful.bg_normal, beautiful.pl_5, "left"))

    if lfs.attributes("/sys/class/power_supply/BAT0/capacity") ~= nil then
        right_layout:add(batwidget)
    else
        right_layout:add(spotifywidget)
    end
    right_layout:add(create_arrow(beautiful.pl_5, beautiful.pl_4, "left"))
    right_layout:add(volwidget)
    right_layout:add(create_arrow(beautiful.pl_4, beautiful.pl_3, "left"))
    right_layout:add(memwidget)
    right_layout:add(create_arrow(beautiful.pl_3, beautiful.pl_2, "left"))
    right_layout:add(cpuwidget)
    right_layout:add(create_arrow(beautiful.pl_2, beautiful.pl_1, "left"))
    right_layout:add(datewidget)
    right_layout:add(create_arrow(beautiful.pl_1, beautiful.bg_normal, "left"))
    if s == 2 or screen.count() == 1 then
        local systray = wibox.widget.systray()
        right_layout:add(systray)
    end
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- lock screen
    awful.key({ modkey,           }, "z", function () awful.util.spawn("slimlock")    end),

    -- volume control
    awful.key({     }, "XF86AudioRaiseVolume", function() awful.util.spawn("amixer set Master 5%+", false) end),
    awful.key({     }, "XF86AudioLowerVolume", function() awful.util.spawn("amixer set Master 5%-", false) end),
    awful.key({     }, "XF86AudioMute", function() awful.util.spawn("amixer sset Master toggle", false) end),

    -- unmount all volumes
    awful.key({ modkey, "Control" }, "c", function() awful.util.spawn("devmon -u") end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 6 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     size_hints_honor = false,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Firefox" },
      properties = { floating = false } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ titlebar stuff
function create_titlebar(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
            awful.button({ }, 1, function()
                client.focus = c
                c:raise()
                awful.mouse.client.move(c)
            end),
            awful.button({ }, 3, function()
                client.focus = c
                c:raise()
                awful.mouse.client.resize(c)
            end)
            )

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(create_arrow(beautiful.pl_1, beautiful.bg_normal, "right"))
    left_layout:add(awful.titlebar.widget.iconwidget(c))
    left_layout:buttons(buttons)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    --right_layout:add(awful.titlebar.widget.floatingbutton(c))
    --right_layout:add(awful.titlebar.widget.maximizedbutton(c))
    --right_layout:add(awful.titlebar.widget.stickybutton(c))
    --right_layout:add(awful.titlebar.widget.ontopbutton(c))
    right_layout:add(awful.titlebar.widget.closebutton(c))
    right_layout:add(create_arrow(beautiful.bg_normal, beautiful.pl_1, "left"))

    -- Close Button

    -- The title goes in the middle
    local middle_layout = wibox.layout.flex.horizontal()
    local title = awful.titlebar.widget.titlewidget(c)
    title:set_align("center")
    middle_layout:add(title)
    middle_layout:buttons(buttons)

    -- Now bring it all together
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)
    layout:set_middle(middle_layout)

    awful.titlebar(c, {size = 0}):set_widget(layout)
end

function should_have_titlebar(c)
    local layout = awful.layout.getname(awful.layout.get(c.screen))
    local floating = awful.client.floating.get(c) or layout == "floating"
    return floating and not c.fullscreen
end

function update_titlebar(c)
    if should_have_titlebar(c) then
        awful.titlebar(c, {size = beautiful.titlebar_height})
    else
        awful.titlebar(c, {size = 0})
    end
end

client.connect_signal("manage", function (c, startup)
    create_titlebar(c)
    update_titlebar(c)

    c:connect_signal("property::floating", function() update_titlebar(c) end)
end)

for s = 1, screen.count() do
    screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        for _, c in pairs(clients) do
            update_titlebar(c)
        end
    end)
end
-- }}}

-- {{{ Function to ensure that certain programs only have one instance of themselves
function run_once(cmd)
        findme = cmd
        firstspace = cmd:find(" ")
        if firstspace then
                findme = cmd:sub(0, firstspace-1)
        end
        awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("CopyAgent")
-- }}}

-- {{{ devmon handling
function handle_device(event, mountpoint, devicename, label)
    local ti = "Unknown device event '" .. event .. "'"
    local te = "Unknown action happned to '" .. devicename .. "'"

    if event == "drive" then
        ti = "Volume '" .. label .. "' mounted"
        te = "'" .. devicename .. "' is now mounted at '" .. mountpoint .. "'"
    elseif event == "remove" then
        ti = "Volume '" .. label .. "' removed"
        te = "'" .. devicename .. "' got removed from '" .. mountpoint .. "'"
    elseif event == "unmount" then
        ti = "Volume '" .. label .. "' unmounted"
        te = "'" .. devicename .. "' got unmounted from '" .. mountpoint .. "'"
    end

    naughty.notify({ title = ti, text = te})
end

run_once("devmon --exec-on-drive   \"echo \\\"handle_device(\'drive\', %d, \'%f\', %l)\\\" | awesome-client -\" "  ..
                "--exec-on-remove  \"echo \\\"handle_device(\'remove\', %d, \'%f\', %l)\\\" | awesome-client -\" "  ..
                "--exec-on-unmount \"echo \\\"handle_device(\'unmount\', %d, \'%f\', %l)\\\" | awesome-client -\" " ..
                "--no-gui")
-- }}}

