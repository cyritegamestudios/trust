local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CursorItem = require('ui/themes/FFXI/CursorItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local JobAbility = require('cylibs/actions/job_ability')
local MenuItem = require('cylibs/ui/menu/menu_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem

function PullActionMenuItem.new(puller, puller_settings, job_name_short, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Job Abilities', 18),
        ButtonItem.default('Spells', 18),
    }, {}, nil, "Pulling", "Configure which actions to use to pull enemies."), PullActionMenuItem)

    self.puller = puller
    self.puller_settings = puller_settings
    self.job_name_short = job_name_short
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

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
end

function PullActionMenuItem:getSpellsMenuItem()
    local chooseSpellsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', self.job_name_short).id
                local allSpells = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.targets:contains('Enemy')
                end):map(function(spell) return spell.en end)

                local chooseSpellsView = self.viewFactory(FFXIPickerView.withItems(allSpells, self.puller_settings.Spells:map(function(spell) return spell:get_name()  end), true))
                chooseSpellsView:setTitle("Choose spells to pull enemies with.")
                chooseSpellsView:setShouldRequestFocus(true)
                chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
                    local spells = selectedItems:map(function(item)
                        return Spell.new(item:getText())
                    end)

                    local currentSpells = self.puller_settings.Spells
                    currentSpells:clear()

                    for spell in spells:it() do
                        currentSpells:append(spell)
                    end
                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(spells:map(function(spell) return spell:get_name()  end)).." to pull for the rest of this session!")
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

        local chooseJobAbilitiesView = self.viewFactory(FFXIPickerView.withItems(allJobAbilities, self.puller_settings.JobAbilities, true))
        chooseJobAbilitiesView:setTitle("Choose job abilities to pull enemies with.")
        chooseJobAbilitiesView:setShouldRequestFocus(true)
        chooseJobAbilitiesView:on_pick_items():addAction(function(_, selectedItems)
            local jobAbilities = selectedItems:map(function(item)
                return JobAbility.new(item:getText())
            end)

            local currentJobAbilities = self.puller_settings.JobAbilities
            currentJobAbilities:clear()

            for jobAbility in jobAbilities:it() do
                currentJobAbilities:append(jobAbility)
            end
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..localization_util.commas(jobAbilities).." to pull for the rest of this session!")
        end)
        return chooseJobAbilitiesView
    end, "Job Abilities", "Choose job abilities to pull enemies with.")
    return chooseJobAbilitiesMenuItem
end

return PullActionMenuItem