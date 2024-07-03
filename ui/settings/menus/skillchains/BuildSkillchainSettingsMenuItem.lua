local BuildSkillchainEditor = require('ui/settings/editors/BuildSkillchainEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')

local BuildSkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuildSkillchainSettingsMenuItem.__index = BuildSkillchainSettingsMenuItem

function BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local builderSettings = T{}
    builderSettings.NumSteps = 2
    builderSettings.Property = 'LightLv4'
    builderSettings.CombatSkills = S{}

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(menuArgs)
        local skillchainBuilderEditor = BuildSkillchainEditor.new(builderSettings, skillchainer)

        skillchainBuilderEditor:setNeedsLayout()
        skillchainBuilderEditor:layoutIfNeeded()

        return skillchainBuilderEditor
    end, "Skillchains", "Find a skillchain."), BuildSkillchainSettingsMenuItem)

    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.builderSettings = builderSettings
    self.skillchainer = skillchainer

    self:reloadSettings()

    return self
end

function BuildSkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Confirm", self:getConfirmMenuItem())
end

function BuildSkillchainSettingsMenuItem:getConfirmMenuItem(delegate)
    local confirmMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
    }, T{}, function(menuArgs)
        local skillchain_builder = SkillchainBuilder.with_skills(L(self.builderSettings.CombatSkills))
        local skillchains = skillchain_builder:build(self.builderSettings.Property, self.builderSettings.NumSteps)
        skillchains = skillchains:slice(1, math.min(skillchains:length(), 75))
        local pickerItems = L(skillchains:map(function(abilities)
            local abilities = L(abilities:map(function(ability) return ability:get_name() end))
            return localization_util.join(abilities, '→')
        end))

        local chooseSkillchainView = FFXIPickerView.withItems(pickerItems, L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge)
        chooseSkillchainView:setTitle("Choose a skillchain.")
        chooseSkillchainView:setAllowsCursorSelection(true)
        chooseSkillchainView:on_pick_items():addAction(function(p, selectedItems)
            local selectedIndexPaths = L(p:getDelegate():getSelectedIndexPaths())
            if selectedIndexPaths:length() > 0 then
                local selectedSkillchain = skillchains[selectedIndexPaths[1].row]

                local currentSettings = self.weaponSkillSettings:getSettings()[self.weaponSkillSettingsMode.value]
                if currentSettings then
                    for i = 1, 6 do
                        if i <= selectedSkillchain:length() then
                            local found = false
                            for combat_skill in currentSettings.Skills:it() do
                                local ability = combat_skill:get_ability(selectedSkillchain[i]:get_name())
                                if ability then
                                    currentSettings.Skillchain[i] = ability
                                    found = true
                                end
                            end
                            if not found then
                                currentSettings.Skillchain[i] = SkillchainAbility.skip()
                            end
                        else
                            currentSettings.Skillchain[i] = SkillchainAbility.auto()
                        end
                    end
                end
            end
            self.weaponSkillSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my skillchain!")
        end)
        return chooseSkillchainView
    end, "Skillchains", "Find a skillchain.")
    return confirmMenuItem
end

return BuildSkillchainSettingsMenuItem