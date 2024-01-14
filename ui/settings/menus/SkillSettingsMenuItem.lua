local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SettingsItemPickerView = require('ui/settings/pickers/SettingsItemPickerView')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')

local SkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillSettingsMenuItem.__index = SkillSettingsMenuItem

function SkillSettingsMenuItem.new(weaponSkillSettings, skillSettings, viewFactory)
    local abilityBlacklistPickerView = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(args)
                local allAbilities = skillSettings:get_abilities(true):compact_map():map(function(ability) return ability:get_name()  end)

                local blacklistPickerView = viewFactory(SettingsItemPickerView.new(weaponSkillSettings, skillSettings.blacklist, skillSettings.blacklist, allAbilities))
                blacklistPickerView:setShouldRequestFocus(true)
                blacklistPickerView:setTitle("Choose abilities to avoid when making skillchains.")
                return blacklistPickerView
            end)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Blacklist', 18),
    }, L{
        Blacklist = abilityBlacklistPickerView
    }), SkillSettingsMenuItem)

    return self
end

return SkillSettingsMenuItem