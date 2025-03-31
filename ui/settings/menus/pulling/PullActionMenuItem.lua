local Approach = require('cylibs/battle/approach')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local MenuItem = require('cylibs/ui/menu/menu_item')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Spell = require('cylibs/battle/spell')

local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GambitTarget = require('cylibs/gambits/gambit_target')
local JobAbilityPickerItemMapper = require('ui/settings/pickers/mappers/JobAbilityPickerItemMapper')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem


function PullActionMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')

    local spellItemMapper = SpellPickerItemMapper.new(L{})
    local jobAbilityItemMapper = JobAbilityPickerItemMapper.new()

    local pullActionSettingsItem = GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, 'PullSettings', S{ GambitTarget.TargetType.Enemy }, function(targets)
        local sections = L{
            L(trust:get_job():get_spells(function(spellId)
                local spell = res.spells[spellId]
                if spell then
                    local valid_targets = S(spell.targets)
                    return targets:intersection(valid_targets):length() > 0
                end
                return false
            end):map(function(spellId)
                return spellItemMapper:map(Spell.new(res.spells[spellId].en))
            end)):unique(function(spell)
                return spell:get_name()
            end),
            L(trust:get_job():get_job_abilities(function(jobAbilityId)
                local jobAbility = res.job_abilities[jobAbilityId]
                if jobAbility then
                    return targets:intersection(S(jobAbility.targets)):length() > 0
                end
                return false
            end):map(function(jobAbilityId)
                return jobAbilityItemMapper:map(JobAbility.new(res.job_abilities[jobAbilityId].en))
            end)),
            L{ Approach.new(), RangedAttack.new() },
        }
        return sections
    end, L{ Condition.TargetType.Enemy, Condition.TargetType.Self }, L{'ApproachPullMode'}, "Ability", "Abilities", function(_)
        return false
    end, function(ability)
        return ability:get_localized_name()
    end, S{ 'Reaction' })
    pullActionSettingsItem:setDefaultGambitTags(L{'Pulling'})

    pullActionSettingsItem:getDisposeBag():add(pullActionSettingsItem:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            local conditions = trust:role_with_type("puller"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition:set_editable(false)
                newGambit:addCondition(condition)
            end
        end
    end), pullActionSettingsItem:onGambitChanged())

    return pullActionSettingsItem
end

return PullActionMenuItem