local SoundTheme = {}
SoundTheme.__index = SoundTheme
SoundTheme.__type = "SoundTheme"

SoundTheme.UI = {}
SoundTheme.UI.Menu = {}
SoundTheme.UI.Menu.Up = 0
SoundTheme.UI.Menu.Down = 1
SoundTheme.UI.Menu.Left = 2
SoundTheme.UI.Menu.Right = 3
SoundTheme.UI.Menu.Enter = 4
SoundTheme.UI.Menu.Escape = 5
SoundTheme.UI.Menu.Error = 6
SoundTheme.UI.Menu.Open = 7
SoundTheme.UI.Menu.Cursor = 8

function SoundTheme.new()
    local self = setmetatable({}, SoundTheme)

    self.soundPathForAction = {}

    return self
end

function SoundTheme:setSoundForAction(action, relativeSoundPath)
    self.soundPathForAction[action] = relativeSoundPath
end

function SoundTheme:getSoundForAction(action)
    return self.soundPathForAction[action]
end

return SoundTheme