local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')
local SkillSettingsMenuItem = require('ui/settings/menus/SkillSettingsMenuItem')

local WeaponSkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WeaponSkillSettingsMenuItem.__index = WeaponSkillSettingsMenuItem

function WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trust, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Skillchains', 18),
        ButtonItem.default('Abilities', 18),
    }, {}), WeaponSkillSettingsMenuItem)

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
    self:setChildMenuItem("Skillchains", self:getSkillchainsMenuItem(activeSkills))
    self:setChildMenuItem("Abilities", self:getAbilitiesMenuItem(activeSkills))
end

function WeaponSkillSettingsMenuItem:getSkillchainsMenuItem(activeSkills)
    local skillchainStepPickerView = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(args)
                local settings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]

                local abilities = settings.Skillchain
                local abilityIndex = args['selected_index'] or 1

                local createSkillchainView = self.viewFactory(SkillchainAbilityPickerView.new(self.weaponSkillSettings, abilities, abilityIndex, self.skillchainer))
                createSkillchainView:setShouldRequestFocus(true)
                return createSkillchainView
            end)

    local skillchainSettingsItem = MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Skip', 18),
        ButtonItem.default('Clear', 18),
        ButtonItem.default('Clear All', 18),
        ButtonItem.default('Change Set', 18),
    }, {
        Edit = skillchainStepPickerView
    },
            function(args)
                local settings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]

                local abilities = settings.Skillchain

                local createSkillchainView = self.viewFactory(SkillchainSettingsEditor.new(self.weaponSkillSettings, abilities))
                createSkillchainView:setShouldRequestFocus(true)
                return createSkillchainView
            end)
    return skillchainSettingsItem
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
            end), childMenuItems)
    return abilitiesMenuItem
end

return WeaponSkillSettingsMenuItem