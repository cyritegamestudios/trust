local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local TargetSettingsMenuItem = setmetatable({}, {__index = MenuItem })
TargetSettingsMenuItem.__index = TargetSettingsMenuItem

function TargetSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Modes', 18),
    }, {

    }, nil, "Targeting", "Configure targeting behavior."), TargetSettingsMenuItem)
    self:setChildMenuItem('Confirm', MenuItem.action(function(parent)
        parent:showMenu(self)
    end))

    self.contentViewConstructor = function(_, infoView)
        local configItems = L{
            BooleanConfigItem.new('Retry', 'Retry Auto Target')
        }
        local targetingConfigEditor = ConfigEditor.new(trustSettings, trustSettings:getSettings()[trustSettingsMode.value].TargetSettings, configItems, infoView)
        return targetingConfigEditor
    end

    self:reloadSettings()

    return self
end

function TargetSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function TargetSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for targeting.",
            L{'AutoTargetMode'})
end

return TargetSettingsMenuItem