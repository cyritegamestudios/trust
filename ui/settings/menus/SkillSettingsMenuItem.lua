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

    local defaultAbility = allAbilities:last()
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
        local blacklist = self.newSkillSettings.Blacklist
        if blacklist:length() == 0 then
            blacklist:append(SkillchainAbility.None)
        end

        local blacklistConfigItem = MultiPickerConfigItem.new('Blacklist', blacklist, L{}:extend(allAbilities:map(function(a) return a:get_name() end)), function(currentAbilities)
            -- TODO: localize this
            return localization_util.commas(currentAbilities, 'and')
        end, 'Blacklist', nil, imageItemForText)
        blacklistConfigItem:setPickerTitle('Blacklist')
        blacklistConfigItem:setPickerDescription('Choose one or more abilities to avoid when making skillchains.')
        local configItems = L{
            PickerConfigItem.new('DefaultAbility', self.newSkillSettings.DefaultAbility, allAbilities, function(ability)
                return ability:get_localized_name()
            end, 'Spam Ability'),
            blacklistConfigItem,
        }

        local skillEditor = ConfigEditor.new(nil, self.newSkillSettings, configItems, nil, nil, showMenu)
        skillEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            skillSettings:set_default_ability(newSettings.DefaultAbility:get_name())
            skillSettings.blacklist = newSettings.Blacklist:filter(function(abilityName) return abilityName ~= SkillchainAbility.None end)

            weaponSkillSettings:saveSettings(true)
            weaponSkillSettings:reloadSettings()

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my "..skillSettings:get_name().." settings!")
        end)
        return skillEditor
    end

    return self
end

return SkillSettingsMenuItem