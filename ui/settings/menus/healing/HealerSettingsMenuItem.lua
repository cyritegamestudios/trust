local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local HealerSettingsMenuItem = setmetatable({}, {__index = MenuItem })
HealerSettingsMenuItem.__index = HealerSettingsMenuItem

function HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
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
    self.trustModeSettings = trustModeSettings
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
    if self.trustSettings:getSettings().Default.CureSettings.StatusRemovals ~= nil then
        self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())
    end
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function HealerSettingsMenuItem:getConfigMenuItem()
    local curesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Reset', 18),
    }, L{}, function(menuArgs, infoView)
        local cureSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value].CureSettings

        local configItems = L{
            ConfigItem.new('Default', 0, 100, 1, function(value) return value.." %" end, "Cure Threshold"),
            ConfigItem.new('Emergency', 0, 100, 1, function(value) return value.." %" end, "Emergency Cure Threshold"),
        }

        local cureAbilityConfigItems = L{}
        local settingsKeys = list.subtract(L(T(cureSettings.Thresholds):keyset()), L{'Default', 'Emergency'})
        for settingsKey in settingsKeys:it() do
            cureAbilityConfigItems:append(ConfigItem.new(settingsKey, 0, 2000, 100, function(value) return value.."" end))
        end

        cureAbilityConfigItems:sort(function(configItem1, configItem2)
            return configItem1:getDescription() < configItem2:getDescription()
        end)

        local cureConfigEditor = ConfigEditor.new(self.trustSettings, cureSettings.Thresholds, configItems:extend(cureAbilityConfigItems))

        self.dispose_bag:add(cureConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
            local configItem = cureConfigEditor:getDataSource():itemAtIndexPath(IndexPath.new(cursorIndexPath.section, 1))
            if configItem then
                if cursorIndexPath.section == 1 then
                    infoView:setDescription("Cure when target HP is <= "..configItem:getCurrentValue().."% and AutoHealMode is set to Auto.")
                elseif cursorIndexPath.section == 2 then
                    infoView:setDescription("Cure when target HP is <= "..configItem:getCurrentValue().."% and AutoHealMode is set to Emergency or to ignore cure cooldown when AutoHealMode is set to Auto.")
                else
                    local description = "Use when: HP missing is >= "..configItem:getCurrentValue()
                    if not S{ 5, configItems:length() }:contains(cursorIndexPath.section) then
                        local nextConfigItem = cureConfigEditor:getDataSource():itemAtIndexPath(cureConfigEditor:getDataSource():getNextIndexPath(cursorIndexPath))
                        description = description.." and <= "..nextConfigItem:getCurrentValue()
                    end
                    description = description.."."
                    infoView:setDescription(description)
                end
            else
                infoView:setDescription("Customize thresholds for cures.")
            end
        end))

        return cureConfigEditor
    end, "Cures", "Customize thresholds for cures.")
    return curesMenuItem
end

function HealerSettingsMenuItem:getBlacklistMenuItem()
    local statusRemovalMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function()
        local cureSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value].CureSettings

        local configItem = MultiPickerConfigItem.new("StatusRemovalBlacklist", cureSettings.StatusRemovals.Blacklist, buff_util.get_all_debuffs():sort(), function(statusEffect)
            return i18n.resource('buffs', 'en', statusEffect)
        end)

        local blacklistPickerView = FFXIPickerView.withConfig(configItem, true)

        blacklistPickerView:getDisposeBag():add(blacklistPickerView:on_pick_items():addAction(function(_, selectedDebuffs)
            cureSettings.StatusRemovals.Blacklist = selectedDebuffs
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't remove these debuffs anymore!")
        end), blacklistPickerView:on_pick_items())

        return blacklistPickerView
    end, "Blacklist", "Choose status ailments to ignore.")
    return statusRemovalMenuItem
end

function HealerSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for healing and status removals.",
            L{'AutoHealMode', 'AutoStatusRemovalMode', 'AutoDetectAuraMode'})
end

return HealerSettingsMenuItem