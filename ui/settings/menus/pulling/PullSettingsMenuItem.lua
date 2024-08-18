local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local PullActionMenuItem = require('ui/settings/menus/pulling/PullActionMenuItem')
local PullSettingsEditor = require('ui/settings/PullSettingsEditor')
local TargetsPickerView = require('ui/settings/pickers/TargetsPickerView')

local PullSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PullSettingsMenuItem.__index = PullSettingsMenuItem

function PullSettingsMenuItem.new(abilities, trust, job_name_short, addon_settings, targets, trust_settings, trust_settings_mode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Targets', 18),
        ButtonItem.default('Actions', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Config', 18),
    }, {

    }, nil, "Pulling", "Configure settings to pull monsters."), PullSettingsMenuItem)

    self.abilities = abilities
    self.puller = trust:role_with_type("puller")
    self.puller_settings = self.puller:get_pull_settings()
    self.job_name_short = job_name_short
    self.addon_settings = addon_settings
    self.targets = targets
    self.trust_settings = trust_settings
    self.trust_settings_mode = trust_settings_mode
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
    self:setChildMenuItem("Actions", PullActionMenuItem.new(self.puller, self.trust_settings, self.trust_settings_mode))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
end

function PullSettingsMenuItem:getTargetsMenuItem()
    local chooseTargetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {
        Confirm = MenuItem.action(nil, "Targets", "Confirm targets to pull."),
        Clear = MenuItem.action(nil, "Targets", "Clear selected targets."),
    },
    function()
        local chooseTargetsView = TargetsPickerView.new(self.addon_settings, self.puller)
        chooseTargetsView:setShouldRequestFocus(true)
        return chooseTargetsView
    end, "Targets", "Add targets to pull.")

    local targetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseTargetsMenuItem,
        Remove = MenuItem.action(nil, "Targets", "Remove selected target from list of enemies to pull."),
    },
    function()
        local pullSettingsView = PullSettingsEditor.new(self.addon_settings, self.puller)
        pullSettingsView:setShouldRequestFocus(true)
        return pullSettingsView
    end, "Targets", "Choose which enemies to pull.")

    return targetsMenuItem
end

function PullSettingsMenuItem:getModesMenuItem()
    local pullModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{ 'AutoPullMode', 'AutoApproachMode' }, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for pulling.")
        return modesView
    end, "Modes", "Change pulling behavior.")
    return pullModesMenuItem
end

function PullSettingsMenuItem:getConfigMenuItem()
    return MenuItem.new(L{
        ButtonItem.default('Save')
    }, L{}, function(menuArgs)
        local allSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value]

        local pullSettings = T{
            Distance = allSettings.PullSettings.Distance,
        }

        local configItems = L{
            ConfigItem.new('Distance', 0, 35, 1, function(value) return value.." yalms" end, "Target Distance"),
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