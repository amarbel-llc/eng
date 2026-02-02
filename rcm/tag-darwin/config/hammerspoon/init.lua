
--   ____                  _            __  __           _
--  / ___|  ___ _ ____   _(_) ___ ___  |  \/  | ___   __| | ___
--  \___ \ / _ \ '__\ \ / / |/ __/ _ \ | |\/| |/ _ \ / _` |/ _ \
--   ___) |  __/ |   \ V /| | (_|  __/ | |  | | (_) | (_| |  __/
--  |____/ \___|_|    \_/ |_|\___\___| |_|  |_|\___/ \__,_|\___|
--

local modal = hs.hotkey.modal.new({ "alt" }, "escape")
modal:bind({}, "escape", function() modal:exit() end)

modal:bind({}, "r", nil, function()
    hs.alert.show("Reloading Hammerspoon Config")
    modal:exit()
    hs.reload()
end)

--  __        ___           _
--  \ \      / (_)_ __   __| | _____      __
--   \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / /
--    \ V  V / | | | | | (_| | (_) \ V  V /
--     \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/
--
--   __  __                                                   _
--  |  \/  | __ _ _ __   __ _  __ _  ___ _ __ ___   ___ _ __ | |_
--  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _ \ '_ \| __|
--  | |  | | (_| | | | | (_| | (_| |  __/ | | | | |  __/ | | | |_
--  |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|\___|_| |_|\__|
--                            |___/

PaperWM = hs.loadSpoon("PaperWM")

local actions = PaperWM.actions.actions()

modal:bind({}, "h", nil, actions.focus_left)
modal:bind({}, "j", nil, actions.focus_down)
modal:bind({}, "k", nil, actions.focus_up)
modal:bind({}, "l", nil, actions.focus_right)

modal:bind({"shift"}, "l", nil, actions.swap_right)
modal:bind({"shift"}, "j", nil, actions.swap_down)
modal:bind({"shift"}, "k", nil, actions.swap_up)
modal:bind({"shift"}, "h", nil, actions.swap_left)

modal:bind({}, ",", nil, actions.decrease_width)
modal:bind({}, ".", nil, actions.increase_width)

PaperWM:start()

PaperWM:bindHotkeys({
    -- switch to a new focused window in tiled grid
    focus_left  = {{"alt"}, "h"},
    focus_right = {{"alt"}, "l"},
    focus_up    = {{"alt"}, "k"},
    focus_down  = {{"alt"}, "j"},

    -- switch windows by cycling forward/backward
    -- (forward = down or right, backward = up or left)
    -- focus_prev = {{"alt", "cmd"}, "k"},
    -- focus_next = {{"alt", "cmd"}, "j"},

    -- move windows around in tiled grid
    swap_left  = {{"alt", "shift"}, "h"},
    swap_right = {{"alt", "shift"}, "l"},
    swap_up    = {{"alt", "shift"}, "k"},
    swap_down  = {{"alt", "shift"}, "j"},

    -- position and resize focused window
    center_window        = {{"alt", "cmd"}, "c"},
    full_width           = {{"alt"}, "f"},
    cycle_width          = {{"alt"}, "r"},
    reverse_cycle_width  = {{"alt"}, "e"},
    cycle_height         = {{"alt", "shift"}, "e"},
    reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

    -- increase/decrease width
    increase_width = {{"alt"}, "."},
    decrease_width = {{"alt"}, ","},

    -- move focused window into / out of a column
    slurp_in = {{"alt"}, "i"},
    barf_out = {{"alt"}, "o"},

    -- move the focused window into / out of the tiling layer
    toggle_floating = {{"alt"}, "space"},
    -- raise all floating windows on top of tiled windows
    focus_floating  = {{"alt", "shift"}, "space"},

    -- focus the first / second / etc window in the current space
    -- focus_window_1 = {{"cmd", "shift"}, "1"},
    -- focus_window_2 = {{"cmd", "shift"}, "2"},
    -- focus_window_3 = {{"cmd", "shift"}, "3"},
    -- focus_window_4 = {{"cmd", "shift"}, "4"},
    -- focus_window_5 = {{"cmd", "shift"}, "5"},
    -- focus_window_6 = {{"cmd", "shift"}, "6"},
    -- focus_window_7 = {{"cmd", "shift"}, "7"},
    -- focus_window_8 = {{"cmd", "shift"}, "8"},
    -- focus_window_9 = {{"cmd", "shift"}, "9"},

    -- switch to a new Mission Control space
    switch_space_1 = {{"alt"}, "1"},
    switch_space_2 = {{"alt"}, "2"},
    switch_space_3 = {{"alt"}, "3"},
    switch_space_4 = {{"alt"}, "4"},
    switch_space_5 = {{"alt"}, "5"},
    switch_space_6 = {{"alt"}, "6"},
    switch_space_7 = {{"alt"}, "7"},
    switch_space_8 = {{"alt"}, "8"},
    switch_space_9 = {{"alt"}, "9"},

    -- move focused window to a new space and tile
    move_window_1 = {{"alt", "shift"}, "1"},
    move_window_2 = {{"alt", "shift"}, "2"},
    move_window_3 = {{"alt", "shift"}, "3"},
    move_window_4 = {{"alt", "shift"}, "4"},
    move_window_5 = {{"alt", "shift"}, "5"},
    move_window_6 = {{"alt", "shift"}, "6"},
    move_window_7 = {{"alt", "shift"}, "7"},
    move_window_8 = {{"alt", "shift"}, "8"},
    move_window_9 = {{"alt", "shift"}, "9"}
})

PaperWM:start()
