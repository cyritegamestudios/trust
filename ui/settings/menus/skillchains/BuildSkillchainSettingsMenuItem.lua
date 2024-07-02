local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local BuildSkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuildSkillchainSettingsMenuItem.__index = BuildSkillchainSettingsMenuItem

function BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local builderSettings = T{}
    builderSettings.NumSteps = 2
    builderSettings.Property = 'LightLv4'

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(menuArgs)
        local configItems = L{
            ConfigItem.new('NumSteps', 2, 6, 1, function(value) return value.."" end),
            PickerConfigItem.new('Property', 'LightLv4', L{
                'Light Lv.4', 'Darkness Lv.4', 'Light', 'Darkness',
                'Distortion', 'Gravitation', 'Fusion', 'Fragmentation',
                'Induration', 'Scission', 'Reverberation', 'Compression',
                'Detonation', 'Impaction', 'Liquefaction', 'Transfixion',
            }),
        }
        local skillchainBuilderEditor = ConfigEditor.new(nil, builderSettings, configItems)
        skillchainBuilderEditor:setShouldRequestFocus(true)
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

function BuildSkillchainSettingsMenuItem:getConfirmMenuItem()
    local confirmMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
    }, T{}, function()
        local skillchains = self.skillchainer.skillchain_builder:build(self.builderSettings.Property, self.builderSettings.NumSteps)
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
                            for combat_skill in currentSettings.Skills:it() do
                                local ability = combat_skill:get_ability(selectedSkillchain[i]:get_name())
                                if ability then
                                    currentSettings.Skillchain[i] = ability
                                end
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