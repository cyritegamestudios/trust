local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')

local ReactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ReactSettingsMenuItem.__index = ReactSettingsMenuItem

function ReactSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local reactSettingsMenuItem = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, 'ReactionSettings', nil, nil, nil, GambitEditorStyle.named('Reaction', 'Reactions'), L{ 'AutoReactMode' })
    reactSettingsMenuItem:setDefaultGambitTags(L{ 'Reaction' })
    return reactSettingsMenuItem
end

return ReactSettingsMenuItem