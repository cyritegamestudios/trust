local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PullActionMenuItem = require('ui/settings/menus/pulling/PullActionMenuItem')
local PullTargetsMenuItem = require('ui/settings/menus/pulling/PullTargetsMenuItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local PullSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PullSettingsMenuItem.__index = PullSettingsMenuItem

function PullSettingsMenuItem.disabled(error_message)
    return MenuItem.action(function() end, "Pulling", "Configure settings to pull monsters.", false, function()
        addon_system_error(error_message)
        return false
    end)
end

function PullSettingsMenuItem.new(abilities, trust, job_name_short, trust_settings, trust_settings_mode, trust_mode_settings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Targets', 18),
        ButtonItem.default('Actions', 18),
        ButtonItem.default('Blacklist', 18),
        ButtonItem.localized('Modes', i18n.translate("Modes")),
        ButtonItem.default('Config', 18),
    }, {

    }, nil, "Pulling", "Configure settings to pull monsters."), PullSettingsMenuItem)

    self.abilities = abilities
    self.trust = trust
    self.puller = trust:role_with_type("puller")
    self.job_name_short = job_name_short
    self.trust_settings = trust_settings
    self.trust_settings_mode = trust_settings_mode
    self.trust_mode_settings = trust_mode_settings
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function PullSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function PullSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Targets", PullTargetsMenuItem.new(self.trust_settings, self.trust_settings_mode))
    self:setChildMenuItem("Actions", PullActionMenuItem.new(self.trust, self.trust_settings, self.trust_settings_mode))
    self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
end

function PullSettingsMenuItem:getBlacklistMenuItem()
    local chooseTargetsMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {},
    function()
        local pullSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings

        local blacklistSettings = {
            Name = '',
        }

        local blacklistConfigEditor = ConfigEditor.new(self.trust_settings, blacklistSettings, L{
            TextInputConfigItem.new('Name', '', 'Mob Name', function(_) return true end, 225)
        })

        self.dispose_bag:add(blacklistConfigEditor:onConfigChanged():addAction(function(newConfigSettings, _)
            local mobName = newConfigSettings.Name
            if mobName and #mobName > 0 then
                pullSettings.Blacklist = pullSettings.Blacklist or L{}
                pullSettings.Blacklist:append(mobName)

                self.trust_settings:saveSettings()
            end
        end), blacklistConfigEditor:onConfigChanged())

        return blacklistConfigEditor
    end, "Blacklist", "Choose which enemies to avoid pulling.")

    local targetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseTargetsMenuItem,
        Remove = MenuItem.action(function()
            if self.pullBlacklistEditor then
                local cursorIndexPath = self.pullBlacklistEditor:getDelegate():getCursorIndexPath()
                if cursorIndexPath then
                    local currentTargets = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Blacklist
                    currentTargets:remove(cursorIndexPath.row)

                    self.pullBlacklistEditor:getDataSource():removeItem(cursorIndexPath)

                    self.trust_settings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've removed this enemy from my naughty list!")
                end
            end
        end, "Blacklist", "Remove selected target from the blacklist.", false, function()
            return self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Targets:length() > 0
        end),
    },
    function()
        local currentTargets = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Blacklist

        local configItem = MultiPickerConfigItem.new("Blacklist", L{}, currentTargets, function(targetName)
            return targetName
        end)

        self.pullBlacklistEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        self.pullBlacklistEditor:setAllowsCursorSelection(true)

        return self.pullBlacklistEditor
    end, "Blacklist", "Choose which enemies to avoid pulling.")

    chooseTargetsMenuItem:setChildMenuItem("Confirm", MenuItem.action(function(menu)
        menu:showMenu(targetsMenuItem)
    end, "Targets", "Confirm enemies to pull."))

    return targetsMenuItem
end

function PullSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trust_mode_settings, "Set modes for pulling.",
            L{ 'AutoPullMode', 'AutoCampMode', 'PullActionMode' })
end

function PullSettingsMenuItem:getConfigMenuItem()
    return MenuItem.new(L{
        ButtonItem.default('Save')
    }, L{}, function(_, infoView)
        local allSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value]

        local pullSettings = T{
            Distance = allSettings.PullSettings.Distance,
            Delay = allSettings.PullSettings.Delay or 0,
            RandomizeTarget = allSettings.PullSettings.RandomizeTarget or false
        }

        local configItems = L{
            ConfigItem.new('Distance', 0, 50, 1, function(value) return value.." yalms" end, "Detection Distance"),
            ConfigItem.new('Delay', 0, 50, 1, function(value) return value.."s" end, "Delay Between Pulls"),
            BooleanConfigItem.new('RandomizeTarget', "Randomize Target"),
        }
        local pullConfigEditor = ConfigEditor.new(self.trust_settings, pullSettings, configItems, infoView)

        self.dispose_bag:add(pullConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            allSettings.PullSettings.Distance = newSettings.Distance
            allSettings.PullSettings.Delay = newSettings.Delay
            allSettings.PullSettings.RandomizeTarget = newSettings.RandomizeTarget
            self.trust_settings:saveSettings(true)
        end), pullConfigEditor:onConfigChanged())

        return pullConfigEditor
    end, "Config", "Configure pull settings.")
end

return PullSettingsMenuItem