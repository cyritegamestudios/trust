local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SettingsItemPickerView = require('ui/settings/pickers/SettingsItemPickerView')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')

local SkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillSettingsMenuItem.__index = SkillSettingsMenuItem

function SkillSettingsMenuItem.new(weaponSkillSettings, skillSettings, viewFactory)
    local onPickItems = function(items)
        if items:length() > 0 then
           skillSettings:set_default_ability(items[1]:getText())
        else
            skillSettings:set_default_ability(nil)
        end
    end

    local abilityBlacklistPickerView = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(args)
                local allAbilities = S(skillSettings:get_abilities(true):compact_map():map(function(ability) return ability:get_name()  end))

                local onPickItems = function(items)
                    skillSettings.blacklist:clear()
                    for item in items:it() do
                        skillSettings.blacklist:append(item:getText())
                    end
                end

                local blacklistPickerView = viewFactory(SettingsItemPickerView.new(weaponSkillSettings, skillSettings.blacklist, allAbilities, onPickItems))
                blacklistPickerView:setShouldRequestFocus(true)
                blacklistPickerView:setTitle("Choose abilities to avoid when making skillchains.")
                return blacklistPickerView
            end)

    local defaultAbilityPickerView = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {
        Confirm = MenuItem.action(nil, skillSettings:get_name(), "Choose an ability to use when spamming or when no skillchain can be made."),
        Clear = MenuItem.action(nil, skillSettings:get_name(), "Choose an ability to use when spamming or when no skillchain can be made.")
    },
    function(args)
        local allAbilities = S(skillSettings:get_abilities(true):compact_map():map(function(ability) return ability:get_name()  end))

        local onPickItems = function(items)
            if items:length() > 0 then
                skillSettings:set_default_ability(items[1]:getText())
            else
                skillSettings:set_default_ability(nil)
            end
        end

        local selectedAbilities = L{}

        local defaultAbility = skillSettings:get_default_ability()
        if defaultAbility then
            selectedAbilities:append(defaultAbility:get_name())
        end

        local abilityPickerView = viewFactory(SettingsItemPickerView.new(weaponSkillSettings, selectedAbilities:compact_map(), allAbilities, onPickItems))
        abilityPickerView:setShouldRequestFocus(true)
        abilityPickerView:setAllowsMultipleSelection(false)
        abilityPickerView:setTitle("Choose an ability.")
        return abilityPickerView
    end)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Blacklist', 18),
        ButtonItem.default('Default', 18)
    }, L{
        Blacklist = abilityBlacklistPickerView,
        Default = defaultAbilityPickerView
    }), SkillSettingsMenuItem)

    return self
end

return SkillSettingsMenuItem