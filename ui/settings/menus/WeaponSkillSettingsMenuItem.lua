local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local SkillchainSettingsMenuItem = require('ui/settings/menus/SkillchainSettingsMenuItem')
local SkillSettingsMenuItem = require('ui/settings/menus/SkillSettingsMenuItem')

local WeaponSkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WeaponSkillSettingsMenuItem.__index = WeaponSkillSettingsMenuItem

function WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Skillchains', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, nil, "Weaponskills", "Configure weapon skill and skillchain settings."), WeaponSkillSettingsMenuItem)

    self.settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]
    self.skillchainer = trust:role_with_type("skillchainer")
    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.trustModeSettings = trustModeSettings
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
    return ModesMenuItem.new(self.trustModeSettings, "Change weapon skill and skillchain behavior.",
            L{'AutoSkillchainMode', 'SkillchainPropertyMode', 'SkillchainDelayMode', 'SkillchainAssistantMode', 'WeaponSkillSettingsMode'})
end

return WeaponSkillSettingsMenuItem