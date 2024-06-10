local Approach = require('cylibs/battle/approach')
local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PullActionSettingsEditor = require('ui/settings/editors/pulling/PullActionSettingsEditor')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Spell = require('cylibs/battle/spell')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem

function PullActionMenuItem.new(puller, trust_settings, trust_settings_mode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {}, function(_)
        local abilities = trust_settings:getSettings()[trust_settings_mode.value].PullSettings.Abilities
        local pullActionsView = PullActionSettingsEditor.new(trust_settings, abilities)
        return pullActionsView
    end, "Pulling", "Configure which actions to use to pull enemies."), PullActionMenuItem)

    self.trust_settings = trust_settings
    self.trust_settings_mode = trust_settings_mode

    self:reloadSettings()

    return self
end

function PullActionMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
end

function PullActionMenuItem:getPullAbilities()
    local sections = L{
        spell_util.get_spells_with_targets(S{'Enemy'}):map(function(spell) return spell.en end),
        player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
            return S{'Enemy'}:intersection(S(jobAbility.targets)):length() > 0
        end):map(function(jobAbility) return jobAbility.en end),
        L{ 'Approach', 'Ranged Attack' }
    }
    return sections
end

function PullActionMenuItem:getAbility(abilityName)
    if res.spells:with('en', abilityName) then
        return Spell.new(abilityName, L{}, L{})
    elseif res.job_abilities:with('en', abilityName) then
        return JobAbility.new(abilityName, L{}, L{})
    elseif abilityName == 'Approach' then
        return Approach.new()
    elseif abilityName == 'Ranged Attack' then
        return RangedAttack.new()
    else
        return nil
    end
end

function PullActionMenuItem:getAddAbilityMenuItem()
    local addAbilityMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(args)
                local imageItemForAbility = function(abilityName, sectionIndex)
                    if sectionIndex == 1 then
                        return AssetManager.imageItemForSpell(abilityName)
                    elseif sectionIndex == 2 then
                        return AssetManager.imageItemForJobAbility(abilityName)
                    else
                        return nil
                    end
                end

                local chooseSpellsView = FFXIPickerView.withSections(self:getPullAbilities(), L{}, true, nil, imageItemForAbility)
                chooseSpellsView:on_pick_items():addAction(function(pickerView, selectedItems)
                    pickerView:getDelegate():deselectAllItems()

                    local selectedAbilities = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Abilities

                    selectedItems = selectedItems:map(function(item) return item:getText() end)
                    for selectedItem in selectedItems:it() do
                        selectedAbilities:append(self:getAbility(selectedItem))
                    end

                    self.trust_settings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(selectedItems).." to pull!")
                end)

                return chooseSpellsView
            end, "Pulling", "Configure which actions to use to pull enemies.")
    return addAbilityMenuItem
end

return PullActionMenuItem