local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('cylibs/modes/ui/modes_view')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')
local SkillchainSettingsMenuItem = require('ui/settings/menus/SkillchainSettingsMenuItem')
local SkillSettingsMenuItem = require('ui/settings/menus/SkillSettingsMenuItem')

local WeaponSkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WeaponSkillSettingsMenuItem.__index = WeaponSkillSettingsMenuItem

function WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trust, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Skillchains', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Weaponskills", "Configure weapon skill and skillchain settings."), WeaponSkillSettingsMenuItem)

    self.settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]
    self.skillchainer = trust:role_with_type("skillchainer")
    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    local getActiveSkills = function(player)
        local settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]
        local activeSkills = L{}
        for skill in settings.Skills:it() do
            if skill:is_valid(player) then
                activeSkills:append(skill)
            end
        end
        return activeSkills
    end

    self.dispose_bag:add(trust:get_party():get_player():on_equipment_change():addAction(function(player)
        self:reloadSettings(getActiveSkills(player))
    end), trust:get_party():get_player():on_equipment_change())

    self.dispose_bag:add(self.skillchainer:on_skills_changed():addAction(function(_, skills)
        self:reloadSettings(skills)
    end), self.skillchainer:on_skills_changed())

    self:reloadSettings(getActiveSkills(trust:get_party():get_player()))

    return self
end

function WeaponSkillSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function WeaponSkillSettingsMenuItem:reloadSettings(activeSkills)
    self:setChildMenuItem("Skillchains", SkillchainSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, self.skillchainer, self.viewFactory))
    self:setChildMenuItem("Abilities", self:getAbilitiesMenuItem(activeSkills))
    self:setChildMenuItem("Modes", self:getModesMenuItem(activeSkills))
end

function WeaponSkillSettingsMenuItem:getAbilitiesMenuItem(activeSkills)
    local settings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]

    local childMenuItems = {}
    for skillSettings in activeSkills:it() do
        childMenuItems[skillSettings:get_name()] = SkillSettingsMenuItem.new(self.weaponSkillSettings, skillSettings, self.viewFactory)
    end
    local abilitiesMenuItem = MenuItem.new(settings.Skills:map(
            function(skill)
                local buttonItem = ButtonItem.default(skill:get_name(), 18)
                buttonItem:setEnabled(activeSkills:contains(skill))
                return buttonItem
            end), childMenuItems, nil, "Abilities", "Customize abilities to use when making skillchains with equipped weapons.")
    return abilitiesMenuItem
end

function WeaponSkillSettingsMenuItem:getModesMenuItem(activeSkills)
    --[[local skillchainDelayMenuItem = MenuItem.new(L{
        ButtonItem.default('Off', 18),
        ButtonItem.default('Maximum', 18),
    }, L{
        Off = MenuItem.action(function()
            handle_set('SkillchainDelayMode', 'Off')
        end, "Delay", state.SkillchainDelayMode:get_description('Off')),
        Maximum = MenuItem.action(function()
            handle_set('SkillchainDelayMode', 'Maximum')
        end, "Delay", state.SkillchainDelayMode:get_description("Maximum")),
    }, nil, "Delay", "Choose the delay between weapon skills when making skillchains.")

    local skillchainPropertiesMenuItem = MenuItem.new(L{
        ButtonItem.default('Auto', 18),
        ButtonItem.default('Light', 18),
        ButtonItem.default('Darkness', 18),
    }, L{
        Auto = MenuItem.action(function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Off')
        end, "Properties", state.SkillchainPropertyMode:get_description('Off')),
        Light = MenuItem.action(function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Light')
        end, "Properties", state.SkillchainPropertyMode:get_description('Light')),
        Darkness = MenuItem.action(function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Darkness')
        end, "Properties", state.SkillchainPropertyMode:get_description('Darkness')),
    }, nil, "Properties", "Choose properties to prioritize when making skillchains.")

    local skillchainSettingsMenuItem = MenuItem.new(L{
        ButtonItem.default('Properties', 18),
        ButtonItem.default('Delay', 18),
    }, L{
        Properties = skillchainPropertiesMenuItem,
        Delay = skillchainDelayMenuItem,
    }, nil, "Skillchains", "Customize skillchain settings.")

    local skillchainModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Skillchain', 18),
        ButtonItem.default('Spam', 18),
        ButtonItem.default('Cleave', 18),
        ButtonItem.default('Off', 18),
    }, L{
        Skillchain = skillchainSettingsMenuItem,
        Spam = MenuItem.action(function()
            handle_set('AutoSkillchainMode', 'Spam')
        end, "Skillchains", state.AutoSkillchainMode:get_description('Spam')),
        Cleave = MenuItem.action(function()
            handle_set('AutoSkillchainMode', 'Cleave')
        end, "Skillchains", state.AutoSkillchainMode:get_description('Cleave')),
        Off = MenuItem.action(function()
            handle_set('AutoSkillchainMode', 'Off')
        end, "Skillchains", state.AutoSkillchainMode:get_description('Off')),
    }, nil, "Modes", "Change skillchain modes.")
    return skillchainModesMenuItem]]

    local skillchainModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{'AutoSkillchainMode', 'SkillchainDelayMode', 'SkillchainPropertyMode'}))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for weapon skills and skillchains.")
        return modesView
    end, "Modes", "Change weapon skill and skillchain behavior.")
    return skillchainModesMenuItem
end

return WeaponSkillSettingsMenuItem