local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SkillSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillSettingsMenuItem.__index = SkillSettingsMenuItem

function SkillSettingsMenuItem.new(weaponSkillSettings, skillSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, nil, skillSettings:get_name(), "Edit settings for "..skillSettings:get_name().."."), SkillSettingsMenuItem)

    local allAbilities = L(skillSettings:get_abilities(true):compact_map()):unique(function(ability) return ability:get_name() end)--:map(function(ability) return ability:get_name() end)

    local defaultAbility = allAbilities:lastWhere(function(a)
        return not a:is_aoe()
    end)
    if skillSettings:get_default_ability() then
        defaultAbility = skillSettings:get_default_ability()
    end

    self.newSkillSettings = {
        DefaultAbility = defaultAbility,
        Blacklist = L{}:extend(skillSettings.blacklist or L{})
    }

    local imageItemForText = function(text)
        return AssetManager.imageItemForWeaponSkill(text)
    end

    self.contentViewConstructor = function(_, _, showMenu)
        local blacklist = skillSettings.blacklist

        local blacklistConfigItem = MultiPickerConfigItem.new('Blacklist', blacklist, L{}:extend(allAbilities:map(function(a) return a:get_name() end)), function(currentAbilities)
            if currentAbilities:empty() then
                return 'None'
            end
            return localization_util.commas(currentAbilities, 'and')
        end, 'Blacklist', nil, imageItemForText)
        blacklistConfigItem:setPickerTitle('Blacklist')
        blacklistConfigItem:setPickerDescription('Choose one or more abilities to avoid when making skillchains.')
        blacklistConfigItem:setNumItemsRequired(0)
        blacklistConfigItem:setOnConfirm(function(newValue)
            skillSettings.blacklist = newValue

            weaponSkillSettings:saveSettings(true)

            addon_message(260, string.format("(%s) Alright, I won't use %s when making skillchains!", windower.ffxi.get_player().name, localization_util.commas(newValue, 'or')))
        end)

        local configItems = L{
            PickerConfigItem.new('DefaultAbility', self.newSkillSettings.DefaultAbility, allAbilities, function(ability)
                return ability:get_localized_name()
            end, 'Spam Ability'),
            blacklistConfigItem,
        }

        local skillEditor = ConfigEditor.new(weaponSkillSettings, self.newSkillSettings, configItems, nil, nil, showMenu)
        skillEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            skillSettings:set_default_ability(newSettings.DefaultAbility:get_name())
            skillSettings.blacklist = newSettings.Blacklist

            weaponSkillSettings:saveSettings(true)
            weaponSkillSettings:reloadSettings()
        end)
        return skillEditor
    end

    return self
end

return SkillSettingsMenuItem