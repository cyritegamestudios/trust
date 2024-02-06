local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')

local RollSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RollSettingsMenuItem.__index = RollSettingsMenuItem

function RollSettingsMenuItem.new(trust, job_name_short, addon_settings, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Targets', 18),
        --ButtonItem.default('Actions', 18),
        ButtonItem.default('Modes', 18),
    }, {

    }, nil, "Pulling", "Configure settings to pull monsters."), PullSettingsMenuItem)

    self.abilities = abilities
    self.puller = trust:role_with_type("puller")
    self.puller_settings = PullerSettings.new(self.puller)
    self.job_name_short = job_name_short
    self.viewFactory = viewFactory
    self.addon_settings = addon_settings
    self.targets = targets
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function RollSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function RollSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Targets", self:getTargetsMenuItem())
    --self:setChildMenuItem("Actions", PullActionMenuItem.new(self.puller, self.puller_settings, self.job_name_short, self.viewFactory))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function RollSettingsMenuItem:getTargetsMenuItem()
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

function RollSettingsMenuItem:getModesMenuItem()
    local pullModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Auto', 18),
        ButtonItem.default('Multi', 18),
        ButtonItem.default('Target', 18),
        ButtonItem.default('All', 18),
        ButtonItem.default('Off', 18),
    }, L{
        Auto = MenuItem.action(function()
            handle_set('AutoPullMode', 'Auto')
        end, "Pulling", state.AutoPullMode:get_description('Auto')),
        Multi = MenuItem.action(function()
            handle_set('AutoPullMode', 'Multi')
        end, "Pulling", state.AutoPullMode:get_description('Multi')),
        Target = MenuItem.action(function()
            handle_set('AutoPullMode', 'Target')
        end, "Pulling", state.AutoPullMode:get_description('Target')),
        All = MenuItem.action(function()
            handle_set('AutoPullMode', 'All')
        end, "Pulling", state.AutoPullMode:get_description('All')),
        Off = MenuItem.action(function()
            handle_set('AutoPullMode', 'Off')
        end, "Pulling", state.AutoPullMode:get_description('Off')),
    }, nil, "Modes", "Change pulling modes.")
    return pullModesMenuItem
end

return RollSettingsMenuItem