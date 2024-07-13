local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local StatusRemovalPickerView = require('ui/settings/pickers/StatusRemovalPickerView')

local HealerSettingsMenuItem = setmetatable({}, {__index = MenuItem })
HealerSettingsMenuItem.__index = HealerSettingsMenuItem

function HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode)
    local menuItems = L{
        ButtonItem.default('Config', 18),
    }
    if trust:role_with_type("statusremover") then
        menuItems:append(ButtonItem.default('Blacklist', 18))
    end
    menuItems:append(ButtonItem.default('Modes', 18))

    local self = setmetatable(MenuItem.new(menuItems, {}, nil, "Healing", "Configure healing and status removal settings."), HealerSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.showStatusRemovals = trust:role_with_type("statusremover") ~= nil
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function HealerSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function HealerSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function HealerSettingsMenuItem:getConfigMenuItem()
    local curesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Reset', 18),
    }, L{}, function(menuArgs)
        local cureSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value].CureSettings

        local configItems = L{
            ConfigItem.new('Default', 0, 100, 1, function(value) return value.." %" end),
            ConfigItem.new('Emergency', 0, 100, 1, function(value) return value.." %" end),
        }

        local settingsKeys = list.subtract(L(T(cureSettings.Thresholds):keyset()), L{'Default', 'Emergency'})
        for settingsKey in settingsKeys:it() do
            configItems:append(ConfigItem.new(settingsKey, 0, 2000, 100, function(value) return value.."" end))
        end

        local cureConfigEditor = ConfigEditor.new(self.trustSettings, cureSettings.Thresholds, configItems)
        return cureConfigEditor
    end, "Cures", "Customize thresholds for cures.")
    return curesMenuItem
end

function HealerSettingsMenuItem:getBlacklistMenuItem()
    local statusRemovalMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local cureSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value].CureSettings

        local blacklistPickerView = StatusRemovalPickerView.new(self.trustSettings, cureSettings.StatusRemovals.Blacklist)
        blacklistPickerView:setTitle('Choose status effects to ignore.')
        blacklistPickerView:setShouldRequestFocus(true)
        return blacklistPickerView
    end, "Blacklist", "Choose status ailments to ignore.")
    return statusRemovalMenuItem
end

function HealerSettingsMenuItem:getModesMenuItem()
    local curesModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoHealMode', 'AutoStatusRemovalMode', 'AutoDetectAuraMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for healing and status removals.")
        return modesView
    end, "Modes", "Set modes for healing and status removals.")
    return curesModesMenuItem
end

return HealerSettingsMenuItem