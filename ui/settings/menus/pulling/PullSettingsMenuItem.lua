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

local PullSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PullSettingsMenuItem.__index = PullSettingsMenuItem

function PullSettingsMenuItem.new(abilities, trust, job_name_short, trust_settings, trust_settings_mode, trust_mode_settings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Targets', 18),
        ButtonItem.default('Actions', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Config', 18),
    }, {

    }, nil, "Pulling", "Configure settings to pull monsters."), PullSettingsMenuItem)

    self.abilities = abilities
    self.trust = trust
    self.puller = trust:role_with_type("puller")
    self.puller_settings = self.puller:get_pull_settings()
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
    self:setChildMenuItem("Targets", self:getTargetsMenuItem())
    self:setChildMenuItem("Actions", PullActionMenuItem.new(self.trust, self.trust_settings, self.trust_settings_mode))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
end

function PullSettingsMenuItem:getTargetsMenuItem()
    local chooseTargetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear All', 18),
    }, {
        Clear = MenuItem.action(nil, "Targets", "Clear selected targets."),
    },
    function()
        local pullSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings

        local allMobs = S{}
        local nearbyMobs = windower.ffxi.get_mob_array()
        for _, mob in pairs(nearbyMobs) do
            if mob.valid_target and mob.spawn_type == 16 then
                allMobs:add(mob.name)
            end
        end

        local configItem = MultiPickerConfigItem.new("Targets", L{}, L(allMobs), function(mobName)
            return mobName
        end)

        local targetPickerView = FFXIPickerView.withConfig(configItem, true)

        self.dispose_bag:add(targetPickerView:on_pick_items():addAction(function(_, newTargetNames)
            targetPickerView:getDelegate():deselectAllItems()

            if newTargetNames:length() > 0 then
                pullSettings.Targets = L(S(pullSettings.Targets + newTargetNames))

                self.trust_settings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my list of enemies to pull!")
            end
        end), targetPickerView:on_pick_items())

        return targetPickerView
    end, "Targets", "Choose which enemies to pull.")

    local targetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseTargetsMenuItem,
        Remove = MenuItem.action(function()
            if self.pullTargetsEditor then
                local cursorIndexPath = self.pullTargetsEditor:getDelegate():getCursorIndexPath()
                if cursorIndexPath then
                    local currentTargets = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Targets
                    currentTargets:remove(cursorIndexPath.row)

                    self.pullTargetsEditor:getDataSource():removeItem(cursorIndexPath)

                    self.trust_settings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't pull this enemy anymore!")
                end
            end
        end, "Targets", "Remove selected target from list of enemies to pull.", false, function()
            return self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Targets:length() > 0
        end),
    },
    function()
        local currentTargets = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Targets

        local configItem = MultiPickerConfigItem.new("Targets", L{}, currentTargets, function(targetName)
            return targetName
        end)

        self.pullTargetsEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        self.pullTargetsEditor:setAllowsCursorSelection(true)

        return self.pullTargetsEditor
    end, "Targets", "Choose which enemies to pull.")

    chooseTargetsMenuItem:setChildMenuItem("Confirm", MenuItem.action(function(menu)
        menu:showMenu(targetsMenuItem)
    end, "Targets", "Confirm enemies to pull."))

    return targetsMenuItem
end

function PullSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trust_mode_settings, "Set modes for pulling.",
            L{ 'AutoPullMode', 'ApproachPullMode', 'AutoCampMode' })
end

function PullSettingsMenuItem:getConfigMenuItem()
    return MenuItem.new(L{
        ButtonItem.default('Save')
    }, L{}, function(_, _)
        local allSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value]

        local pullSettings = T{
            Distance = allSettings.PullSettings.Distance,
        }

        local configItems = L{
            ConfigItem.new('Distance', 0, 50, 1, function(value) return value.." yalms" end, "Target Distance"),
        }
        local pullConfigEditor = ConfigEditor.new(self.trust_settings, pullSettings, configItems)

        self.dispose_bag:add(pullConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            allSettings.PullSettings.Distance = newSettings.Distance

            self.trust_settings:saveSettings(true)
        end), pullConfigEditor:onConfigChanged())

        return pullConfigEditor
    end, "Config", "Configure pull settings.")
end

return PullSettingsMenuItem