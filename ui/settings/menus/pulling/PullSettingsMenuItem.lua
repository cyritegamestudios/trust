local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local PullActionMenuItem = require('ui/settings/menus/pulling/PullActionMenuItem')
local PullSettingsEditor = require('ui/settings/PullSettingsEditor')
local TargetsPickerView = require('ui/settings/pickers/TargetsPickerView')

local PullerSettings = {}
PullerSettings.__index = PullerSettings
PullerSettings.__class = "PullerSettings"

function PullerSettings.new(puller)
    local self = setmetatable({}, PullerSettings)
    self.puller = puller
    return self
end

function PullerSettings:getSettings()
    return self.puller:get_pull_settings()
end

function PullerSettings:saveSettings()
    --self.puller:set_pull_settings(self.puller:get_pull_settings())
end

local PullSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PullSettingsMenuItem.__index = PullSettingsMenuItem

function PullSettingsMenuItem.new(abilities, trust, job_name_short, addon_settings, targets, trust_settings, trust_settings_mode, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Targets', 18),
        ButtonItem.default('Actions', 18),
        ButtonItem.default('Modes', 18),
    }, {

    }, nil, "Pulling", "Configure settings to pull monsters."), PullSettingsMenuItem)

    self.abilities = abilities
    self.puller = trust:role_with_type("puller")
    self.puller_settings = self.puller:get_pull_settings()
    self.job_name_short = job_name_short
    self.viewFactory = viewFactory
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

    self.viewFactory = nil
end

function PullSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Targets", self:getTargetsMenuItem())
    self:setChildMenuItem("Actions", PullActionMenuItem.new(self.puller, self.trust_settings, self.trust_settings_mode, self.viewFactory))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
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
        local chooseTargetsView = self.viewFactory(TargetsPickerView.new(self.addon_settings, self.puller))
        chooseTargetsView:setTitle("Choose mobs to pull from nearby targets.")
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
        local pullSettingsView = self.viewFactory(PullSettingsEditor.new(self.addon_settings, self.puller))
        pullSettingsView:setShouldRequestFocus(true)
        return pullSettingsView
    end, "Targets", "Choose which enemies to pull.")

    return targetsMenuItem
end

function PullSettingsMenuItem:getModesMenuItem()
    local pullModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{ 'AutoPullMode', 'AutoApproachMode' }))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for pulling.")
        return modesView
    end, "Modes", "Change pulling behavior.")
    return pullModesMenuItem
end

return PullSettingsMenuItem