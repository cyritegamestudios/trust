local Approach = require('cylibs/battle/approach')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local MenuItem = require('cylibs/ui/menu/menu_item')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Spell = require('cylibs/battle/spell')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem

function PullActionMenuItem.new(puller, trust_settings, trust_settings_mode, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Job Abilities', 18),
        ButtonItem.default('Spells', 18),
        ButtonItem.default('Other', 18),
    }, {}, nil, "Pulling", "Configure which actions to use to pull enemies."), PullActionMenuItem)

    self.puller = puller
    self.trust_settings = trust_settings
    self.trust_settings_mode = trust_settings_mode

    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self.jobIds = L{
        windower.ffxi.get_player().main_job_id,
        windower.ffxi.get_player().sub_job_id
    }
    self:reloadSettings()

    return self
end

function PullActionMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function PullActionMenuItem:reloadSettings()
    self:setChildMenuItem("Job Abilities", self:getJobAbilitiesMenuItem())
    self:setChildMenuItem("Spells", self:getSpellsMenuItem())
    self:setChildMenuItem("Other", self:getOtherAbilitiesMenuItem())
end

function PullActionMenuItem:getSpellsMenuItem()
    local chooseSpellsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function()
                local allSpells = spell_util.get_spells(function(spell)
                    for jobId in self.jobIds:it() do
                        if spell.levels[jobId] ~= nil and spell.targets:contains('Enemy') then
                            return true
                        end
                    end
                    return false
                end):map(function(spell) return spell.en end)

                local selectedSpells = self.puller:get_pull_settings().Abilities:filter(function(ability)
                    return ability.__class == Spell.__class
                end):map(function(spell)
                    return spell:get_name()
                end)

                local chooseSpellsView = self.viewFactory(FFXIPickerView.withItems(allSpells, selectedSpells, true))
                chooseSpellsView:setTitle("Choose spells to pull enemies with.")
                chooseSpellsView:setShouldRequestFocus(true)
                chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
                    local spells = selectedItems:map(function(item)
                        return Spell.new(item:getText(), L{}, L{})
                    end)

                    self:replaceAbilities(L{ Spell.__class }, spells)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(spells:map(function(spell) return spell:get_name()  end)).." to pull!")
                end)
                return chooseSpellsView
            end, "Pulling", "Choose spells to pull enemies with.")
    return chooseSpellsMenuItem

end

function PullActionMenuItem:getJobAbilitiesMenuItem()
    local chooseJobAbilitiesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function()
        local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
            return S{'Enemy'}:intersection(S(jobAbility.targets)):length() > 0
        end):map(function(jobAbility) return jobAbility.en end)

        local selectedAbilities = self.puller:get_pull_settings().Abilities:filter(function(ability)
            return ability.__class == JobAbility.__class
        end):map(function(jobAbility) return jobAbility:get_name() end)

        local chooseJobAbilitiesView = self.viewFactory(FFXIPickerView.withItems(allJobAbilities, selectedAbilities, true))
        chooseJobAbilitiesView:setTitle("Choose job abilities to pull enemies with.")
        chooseJobAbilitiesView:setShouldRequestFocus(true)
        chooseJobAbilitiesView:on_pick_items():addAction(function(_, selectedItems)
            local jobAbilities = selectedItems:map(function(item)
                return JobAbility.new(item:getText(), L{}, L{})
            end)

            self:replaceAbilities(L{ JobAbility.__class }, jobAbilities)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(jobAbilities:map(function(jobAbility) return jobAbility:get_name() end)).." to pull!")
        end)
        return chooseJobAbilitiesView
    end, "Job Abilities", "Choose job abilities to pull enemies with.")
    return chooseJobAbilitiesMenuItem
end

function PullActionMenuItem:getOtherAbilitiesMenuItem()
    local chooseOtherAbilitiesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function()
                local allAbilities = L{
                    'Approach',
                    'Ranged Attack'
                }

                local selectedAbilities = self.puller:get_pull_settings().Abilities:filter(function(ability)
                    return L{ Approach.__class, RangedAttack.__class }:contains(ability.__class)
                end):map(function(ability) return ability:get_name() end)

                local chooseOtherAbilitiesView = self.viewFactory(FFXIPickerView.withItems(allAbilities, selectedAbilities, true))
                chooseOtherAbilitiesView:setTitle("Choose actions to pull enemies with.")
                chooseOtherAbilitiesView:setShouldRequestFocus(true)
                chooseOtherAbilitiesView:on_pick_items():addAction(function(_, selectedItems)
                    local abilities = selectedItems:map(function(item)
                        if item:getText() == 'Approach' then
                            return Approach.new()
                        elseif item:getText() == 'Ranged Attack' then
                            return RangedAttack.new()
                        end
                        return nil
                    end)

                    self:replaceAbilities(S{ Approach.__class, RangedAttack.__class }, abilities)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(abilities:map(function(ability) return ability:get_name() end)).." to pull for the rest of this session!")
                end)
                return chooseOtherAbilitiesView
            end, "Other", "Choose actions to pull enemies with.")
    return chooseOtherAbilitiesMenuItem
end

function PullActionMenuItem:replaceAbilities(abilityClasses, abilities)
    local currentAbilities = self.puller:get_pull_settings().Abilities

    local newAbilities = currentAbilities:filter(function(ability)
        return not abilityClasses:contains(ability.__class)
    end)
    newAbilities:extend(abilities)

    currentAbilities:clear()
    currentAbilities:extend(newAbilities)

    local pull_settings = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings
    if pull_settings == nil then
        self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings = {}
    end
    self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Abilities = currentAbilities
    self.trust_settings:saveSettings(true)
end

return PullActionMenuItem