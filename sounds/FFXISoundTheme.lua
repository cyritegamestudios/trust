local SoundTheme = require('cylibs/sounds/sound_theme')

local FFXISoundTheme = {}
FFXISoundTheme.__index = setmetatable({}, {__index = SoundTheme })
FFXISoundTheme.__type = "FFXISoundTheme"

function FFXISoundTheme.default()
    local self = setmetatable(SoundTheme.new(), FFXISoundTheme)

    for action in L{ SoundTheme.UI.Menu.Up, SoundTheme.UI.Menu.Down, SoundTheme.UI.Menu.Left, SoundTheme.UI.Menu.Right }:it() do
        self:setSoundForAction(action, 'menu/cursor')
    end

    self:setSoundForAction(SoundTheme.UI.Menu.Cursor, 'menu/cursor')
    self:setSoundForAction(SoundTheme.UI.Menu.Enter, 'menu/enter')
    self:setSoundForAction(SoundTheme.UI.Menu.Escape, 'menu/escape')
    self:setSoundForAction(SoundTheme.UI.Menu.Error, 'menu/error')
    self:setSoundForAction(SoundTheme.UI.Menu.Open, 'menu/open')

    return self
end

return FFXISoundTheme