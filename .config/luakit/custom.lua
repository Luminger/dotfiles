---------------------------------
-- custom luakit configuration --
---------------------------------

-- require this script at the end of the 'user script loading' section

local pairs = pairs
local follow = require("follow")
local webview = require("webview")
local lousy = require("lousy")

local key, buf, but = lousy.bind.key, lousy.bind.buf, lousy.bind.but
local cmd, any = lousy.bind.cmd, lousy.bind.any
local add_binds = add_binds

-- enable scrollbars
--webview.init_funcs.show_scrollbars = function(view)
--        view.show_scrollbars = true
--end

-- Use a custom charater set for hint labels
local s = follow.label_styles
follow.label_maker = s.sort(s.reverse(s.charset("asdfghjkl")))

-- Overwrite/Add some keybindings
local bindings = {
    command = {
        cmd("q[uit]", "Close the current window.",
            function (w, a, o) w:save_session() w:close_win(o.bang) end)
    }
}

for modename, modebinds in pairs(bindings) do
    -- For overwritten commands, this will not update the description but it
    -- will be executed befor the "original" from binds.lua.
    --
    -- The right solution would be to replace the command corretly, but I'm
    -- lazy and I don't need to update the description currently. So the 'true'
    -- stays for now.
    add_binds(modename, modebinds, true)
end
