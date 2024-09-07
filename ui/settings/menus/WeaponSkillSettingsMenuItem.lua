local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModeConfigEditor = require('ui/settings/editors/config/ModeConfigEditor')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')
local SkillchainSettingsMenuItem = require('ui/settings/menus/SkillchainSettingsMenuItem')
local SkillSettingsMenuItem = require('ui/settings/menus/SkillSettingsMenuItem')

local WeaponSkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WeaponSkillSettingsMenuItem.__index = WeaponSkillSettingsMenuItem

function WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Skillchains', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Weaponskills", "Configure weapon skill and skillchain settings."), WeaponSkillSettingsMenuItem)

    self.settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]
    self.skillchainer = trust:role_with_type("skillchainer")
    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
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
end

function WeaponSkillSettingsMenuItem:reloadSettings(activeSkills)
    self:setChildMenuItem("Skillchains", SkillchainSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, self.skillchainer))
    self:setChildMenuItem("Abilities", self:getAbilitiesMenuItem(activeSkills))
    self:setChildMenuItem("Modes", self:getModesMenuItem(activeSkills))
end

function WeaponSkillSettingsMenuItem:getAbilitiesMenuItem(activeSkills)
    local settings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]

    local childMenuItems = {}
    for skillSettings in activeSkills:it() do
        childMenuItems[skillSettings:get_name()] = SkillSettingsMenuItem.new(self.weaponSkillSettings, skillSettings)
    end
    local abilitiesMenuItem = MenuItem.new(settings.Skills:map(
            function(skill)
                local buttonItem = ButtonItem.default(skill:get_name(), 18)
                buttonItem:setEnabled(activeSkills:contains(skill))
                return buttonItem
            end), childMenuItems, nil, "Abilities", "Customize abilities to use when making skillchains with equipped weapons.")
    return abilitiesMenuItem
end

function WeaponSkillSettingsMenuItem:getModesMenuItem()
    local skillchainModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModeConfigEditor.new(L{'AutoSkillchainMode', 'SkillchainAssistantMode', 'SkillchainDelayMode', 'SkillchainPropertyMode', 'WeaponSkillSettingsMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for weapon skills and skillchains.")
        return modesView
    end, "Modes", "Change weapon skill and skillchain behavior.")
    return skillchainModesMenuItem
end

return WeaponSkillSettingsMenuItem