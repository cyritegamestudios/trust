local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PartySkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/PartySkillchainSettingsMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local skillchain_util = require('cylibs/util/skillchain_util')


local BuildSkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuildSkillchainSettingsMenuItem.__index = BuildSkillchainSettingsMenuItem

function BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer, selectPartyCombatSkillIds)
    local builderSettings = T{
        NumSteps = 2,
        Property = "Light Lv.4",
        CombatSkills = skillchainer:get_party():get_player():get_combat_skill_ids(),
        IncludeAeonic = false
    }

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Search', 18),
    }, {}, function(_, infoView, showMenu)
        local activeCombatSkillIds = L(skillchainer:get_party():get_player():get_combat_skill_ids())
        if selectPartyCombatSkillIds then
            for partyMember in skillchainer:get_party():get_party_members(false):it() do
                activeCombatSkillIds = activeCombatSkillIds + partyMember:get_combat_skill_ids()
            end
        end

        local skillPickerItem = MultiPickerConfigItem.new('CombatSkills',  activeCombatSkillIds, L{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26, 36, 38 }, function(skillIds)
            return localization_util.commas(skillIds:map(function(skillId) return i18n.resource('skills', 'en', res.skills[skillId].en) end))
        end, "Skills")
        skillPickerItem:setPickerTitle("Skills")
        skillPickerItem:setPickerDescription("Choose one or more skill for the skillchain.")
        skillPickerItem:setPickerTextFormat(function(skillId)
            return i18n.resource('skills', 'en', res.skills[skillId].en)
        end)

        local configItems = L{
            ConfigItem.new('NumSteps', 2, 6, 1, function(value) return value.."" end, "Number of Steps"),
            PickerConfigItem.new('Property', builderSettings.Property, skillchain_util.all_skillchain_properties()),
            BooleanConfigItem.new('IncludeAeonic', 'Enable Aeonic'),
            skillPickerItem
        }

        local skillchainBuilderEditor = ConfigEditor.new(nil, builderSettings, configItems, infoView, nil, showMenu)

        skillchainBuilderEditor:onConfigItemChanged():addAction(function(key, newValue, _)
            builderSettings[key] = newValue
        end)

        skillchainBuilderEditor:setNeedsLayout()
        skillchainBuilderEditor:layoutIfNeeded()

        return skillchainBuilderEditor
    end, "Skillchains", "Find a skillchain."), BuildSkillchainSettingsMenuItem)

    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.builderSettings = builderSettings
    self.skillchainer = skillchainer
    self.partySkillchainSettingsMenuItem = PartySkillchainSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, self.skillchainer)

    self:reloadSettings()

    return self
end

function BuildSkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Search", self:getConfirmMenuItem())
    self:setChildMenuItem("Reset", MenuItem.action(function()
        self:resetSettings()
    end), "Skillchains", "Reset to default settings.")
end

function BuildSkillchainSettingsMenuItem:getConfirmMenuItem()
    local confirmMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Filter', 18),
    }, {
        Confirm = self.partySkillchainSettingsMenuItem,
    }, function(menuArgs, infoView)
        self.currentPage = 1

        local skillchain_builder = SkillchainBuilder.with_skills(L(self.builderSettings.CombatSkills))
        skillchain_builder.include_aeonic = self.builderSettings.IncludeAeonic

        local skillchains = skillchain_builder:build(self.builderSettings.Property, self.builderSettings.NumSteps)
        self.skillchains = skillchains

        self.currentSkillchains = L{}:extend(skillchains):slice(1, math.min(skillchains:length(), 500))

        local configItem = MultiPickerConfigItem.new("Skillchains", L{}, self.currentSkillchains, function(abilities)
            local abilities = L(abilities:map(function(ability) return ability:get_localized_name() end))
            return localization_util.join(abilities, '→')
        end, "Skillchains", nil, nil, function(abilities)
            local abilities = L(abilities:map(function(ability) return ability:get_localized_name() end))
            return localization_util.join(abilities, '→')
        end)
        configItem:setNumItemsRequired(1, 1)

        local chooseSkillchainView = FFXIPickerView.new(configItem, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, 17)
        chooseSkillchainView:setAllowsCursorSelection(true)

        chooseSkillchainView:on_pick_items():addAction(function(_, selectedItems)
            self.partySkillchainSettingsMenuItem:setSkillchain(selectedItems[1])
        end)

        return chooseSkillchainView
    end, "Skillchains", "Find a skillchain.")
    return confirmMenuItem
end

function BuildSkillchainSettingsMenuItem:resetSettings()
    self.builderSettings.NumSteps = 2
    self.Property = 'LightLv4'
    self.CombatSkills = L{}
end

return BuildSkillchainSettingsMenuItem