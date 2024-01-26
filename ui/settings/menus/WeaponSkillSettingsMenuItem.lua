local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
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
    self:setChildMenuItem("Skillchains", SkillchainSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, self.viewFactory))
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
            end), childMenuItems)
    return abilitiesMenuItem
end

function WeaponSkillSettingsMenuItem:getModesMenuItem(activeSkills)
    local skillchainDelayMenuItem = MenuItem.new(L{
        ButtonItem.default('Off', 18),
        ButtonItem.default('Maximum', 18),
    }, L{
        Off = function()
            handle_set('SkillchainDelayMode', 'Off')
        end,
        Maximum = function()
            handle_set('SkillchainDelayMode', 'Maximum')
        end,
    }, nil)

    local skillchainPropertiesMenuItem = MenuItem.new(L{
        ButtonItem.default('Auto', 18),
        ButtonItem.default('Light', 18),
        ButtonItem.default('Darkness', 18),
        ButtonItem.default('Delay', 18),
    }, L{
        Auto = function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Off')
        end,
        Light = function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Light')
        end,
        Darkness = function()
            state.AutoSkillchainMode:set('Auto')
            handle_set('SkillchainPropertyMode', 'Darkness')
        end,
        Delay = skillchainDelayMenuItem,
    }, nil)

    local skillchainModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Skillchain', 18),
        ButtonItem.default('Spam', 18),
        ButtonItem.default('Cleave', 18),
        ButtonItem.default('Off', 18),
    }, L{
        Skillchain = skillchainPropertiesMenuItem,
        Spam = function()
            handle_set('AutoSkillchainMode', 'Spam')
        end,
        Cleave = function()
            handle_set('AutoSkillchainMode', 'Cleave')
        end,
        Off = function()
            handle_set('AutoSkillchainMode', 'Off')
        end
    }, nil)
    return skillchainModesMenuItem
end

return WeaponSkillSettingsMenuItem