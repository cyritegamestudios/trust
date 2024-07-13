local Approach = require('cylibs/battle/approach')
local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PullActionSettingsEditor = require('ui/settings/editors/pulling/PullActionSettingsEditor')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Spell = require('cylibs/battle/spell')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem

function PullActionMenuItem.new(puller, trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, nil, "Pulling", "Configure which actions to use to pull enemies."), PullActionMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local abilities = trustSettings:getSettings()[trustSettingsMode.value].PullSettings.Abilities
        local pullActionsView = PullActionSettingsEditor.new(trustSettings, abilities)
        self.dispose_bag:add(pullActionsView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local ability = abilities[indexPath.row]
            if ability then
                local description = ability:get_conditions():map(function(condition)
                    return condition:tostring()
                end)
                infoView:setDescription("Use when: "..localization_util.commas(description))
            end
        end, pullActionsView:getDelegate():didMoveCursorToItemAtIndexPath()))
        return pullActionsView
    end

    self:reloadSettings()

    return self
end

function PullActionMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
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
            function(_, _)
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

                    local selectedAbilities = self.trustSettings:getSettings()[self.trustSettingsMode.value].PullSettings.Abilities

                    selectedItems = selectedItems:map(function(item) return item:getText() end)
                    for selectedItem in selectedItems:it() do
                        selectedAbilities:append(self:getAbility(selectedItem))
                    end

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(selectedItems).." to pull!")
                end)

                return chooseSpellsView
            end, "Pulling", "Configure which actions to use to pull enemies.")
    return addAbilityMenuItem
end

function PullActionMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode)
end

return PullActionMenuItem