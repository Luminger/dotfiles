import os
import subprocess
from libqtile.config import Key, Screen, Group, Drag, Click
from libqtile.command import lazy
from libqtile import layout, bar, widget, hook

mod = "mod4"
rmod = "mod1"

keys = [
    # Basic commands
    Key(
        [mod, "shift"], "e",
        lazy.shutdown()
    ),
    Key(
        [mod, "shift"], "r",
        lazy.restart()
    ),
    Key(
        [mod], "c",
        lazy.window.kill()
    ),
    Key(
        [rmod, "shift"], "p",
        #lambda: subprocess.run("xdotool", "click", "1", "click", "2")
        lazy.spawn("xdotool click 2")
    ),
    Key(
        [mod, "shift"], "space",
        lazy.layout.flip()
    ),

    # Switch between windows in current stack pane
    Key(
        [mod], "k",
        lazy.layout.down()
    ),
    Key(
        [mod], "j",
        lazy.layout.up()
    ),

    # Move windows up or down in current stack
    Key(
        [mod, "control"], "k",
        lazy.layout.shuffle_down()
    ),
    Key(
        [mod, "control"], "j",
        lazy.layout.shuffle_up()
    ),

    # Switch window focus to other pane(s) of stack
    Key(
        [mod], "space",
        lazy.layout.next()
    ),

    # Swap panes of split stack
    Key(
        [mod, "shift"], "space",
        lazy.layout.rotate()
    ),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"], "Return",
        lazy.layout.toggle_split()
    ),
    Key([mod], "Return", lazy.spawn("termite")),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout()),
    Key([mod, "shift"], "c", lazy.window.kill()),

    Key([mod, "control"], "r", lazy.restart()),
    Key([mod, "control"], "q", lazy.shutdown()),
    Key([mod], "r", lazy.spawncmd()),
]

groups = [Group(i) for i in "1234567890"]

for i in groups:
    # mod1 + letter of group = switch to group
    keys.append(
        Key([mod], i.name, lazy.group[i.name].toscreen())
    )

    # mod1 + shift + letter of group = switch to & move focused window to group
    keys.append(
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name))
    )

class Theme:
    bar = {
        'size': 20,
        #'background': '3a4055',
        'background': '555555',
        }
    widget = {
        'font': 'Terminus',
        'fontsize': 11,
        'background': bar['background'],
        #'foreground': 'f9f7f3',
        'foreground': 'ffffff',
        }
    groupbox = {
        'highlight_method': 'block',
        'inactive': 'aaaaaa',
        'borderwidth': 1,
        'padding': 1,
        'this_current_screen_border': '888888',
        'rounded': False,
        }
    sep = {
        'background': bar['background'],
        'height_percent': 50,
        }
    checkupdates = {
        'display_format': '{updates}',
        'distro': 'Arch_checkupdates',
    }
    systray = widget.copy()
    systray.update({
        'icon_size': 16,
        })
    pacman = widget.copy()
    pacman.update({
        'foreground': 'ff0000',
        'unavailable': '00ff00',
        })
    battery = widget.copy()
    battery_text = battery.copy()
    battery_text.update({
        'low_foreground': 'FF0000',
        'charge_char': "↑ ",
        'discharge_char': "↓ ",
        'format': '{char}{hour:d}:{min:02d}',
        })
    layout = {
        'margin': 10,
        'border_width': 1,
        'single_border_width': 1,
        #'border_focus': '5a647e',
        #'border_normal': '2b2b2b',
        'border_focus': '888888',
        'border_normal': '555555',
    }

layouts = [
    layout.Tile(ratio=0.5, **Theme.layout),
    layout.Matrix(**Theme.layout),
    layout.Floating(**Theme.layout),
    layout.Max(**Theme.layout),
    #layout.MonadTall(**Theme.layout),
    #layout.Stack(num_stacks=2, **Theme.layout)
]

icons = {
	"temp": "",     # fa-fire-extinguisher
	"battery": "",  # fa-battery-three-quarters
	"light": "",    # fa-lightbulb-o
	"volume": "",   # fa-bullhorn
	"layout": "",   # fa-window-restore
	"clock": "",    # fa-clock-o
	"pacman": "",   # fa-download
}

widget_defaults = Theme.widget

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(**Theme.groupbox),
                widget.Prompt(),
                widget.WindowTabs(),

                widget.Systray(**Theme.systray),
		widget.Sep(**Theme.sep, padding=10),
		widget.TextBox(text=icons['layout']),
                widget.CurrentLayout(),
		widget.TextBox(text=icons['pacman']),
                widget.CheckUpdates(**Theme.checkupdates),
		widget.TextBox(text=icons['battery']),
                widget.Battery(**Theme.battery_text),
		widget.TextBox(text=icons['clock']),
                widget.Clock(format='%a, %b %d %H:%M'),
            ],
            **Theme.bar
        ),
    ),
]

# Drag (floating) layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position(),
        start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
        start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []
main = None
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating()
auto_fullscreen = True
focus_on_window_activation = "smart"
wmname = "LG3D"

# restart to reset wallpaper and to account for possibly new screens
@hook.subscribe.screen_change
def restart_on_randr(qtile, ev):
    home = os.path.expanduser('~/wallpaper/MuPRyui.jpg')
    qtile.spawn("feh --bg-fill {}".format(home))
    qtile.cmd_restart()
