---------------------------
-- Wrapper around a status removal spell.
-- @class module
-- @name StatusRemoval

local StatusRemovalAction = require('cylibs/actions/status_removal')

local Spell = require('cylibs/battle/spell')
local StatusRemoval = setmetatable({}, {__index = Spell })
StatusRemoval.__index = StatusRemoval
StatusRemoval.__type = "StatusRemoval"
StatusRemoval.__class = "StatusRemoval"

-------
-- Default initializer for a new status removal spell.
-- @tparam string spell_name Localized name of the spell
-- @tparam list job_ability_names List of job abilities to use, if any
-- @tparam number debuff_id Debuff to remove (see res/buffs.lua)
-- @tparam list conditions List of conditions that must be satisfied to cast the spell (optional)
-- @treturn StatusRemoval A status removal spell
function StatusRemoval.new(spell_name, job_ability_names, debuff_id, conditions)
    if debuff_id == 0 then
        conditions = (conditions or L{}) + L{
            NotCondition.new(L{ HasBuffCondition.new('Reraise') }),
            StatusCondition.new('Dead', 4, Condition.Operator.GreaterThanOrEqualTo)
        }
    end
    local self = setmetatable(Spell.new(spell_name, job_ability_names, L{}, nil, conditions), StatusRemoval)
    self.debuff_id = debuff_id
    return self
end

-------
-- Return the Action to cast this spell on a target. Optionally first uses job abilities where conditions are satisfied.
-- @tparam number target_index Target for the spell
-- @treturn Action Action to cast the spell
function StatusRemoval:to_action(target_index, player, job_abilities)
    local actions = L{}

    local job_abilities = (job_abilities or self:get_job_abilities()):map(function(job_ability_name)
        local conditions = L{}

        local job_ability = res.job_abilities:with('en', job_ability_name)
        if job_ability.status then
            conditions:append(NotCondition.new(L{ HasBuffCondition.new(res.buffs[job_ability.status].en, player:get_mob().index) }, windower.ffxi.get_player().index))
        end
        return JobAbility.new(job_ability_name, conditions)
    end):filter(function(job_ability)
        return Condition.check_conditions(job_ability:get_conditions(), player:get_mob().index)
    end)

    for job_ability in job_abilities:it() do
        if job_ability.type == 'Scholar' then
            actions:append(StrategemAction.new(job_ability:get_job_ability_name()))
            actions:append(WaitAction.new(0, 0, 0, 1))
        else
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability:get_job_ability_name()))
            actions:append(WaitAction.new(0, 0, 0, 1))
        end
    end

    actions:append(StatusRemovalAction.new(0, 0, 0, self:get_spell().id, target_index, self.debuff_id, player))
    actions:append(WaitAction.new(0, 0, 0, 2))

    return SequenceAction.new(actions, 'spell_'..self:get_spell().en)
end

function StatusRemoval:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name() then
        return true
    end
    return false
end

return StatusRemoval