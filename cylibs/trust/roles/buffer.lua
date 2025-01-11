local BuffConflictsCondition = require('cylibs/conditions/buff_conflicts')
local BuffTracker = require('cylibs/battle/buff_tracker')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Buffer = setmetatable({}, {__index = Gambiter })
Buffer.__index = Buffer
Buffer.__class = "Buffer"

function Buffer.new(action_queue, buff_settings, state_var)
    local self = setmetatable(Gambiter.new(action_queue, {}, nil, state_var or state.AutoBuffMode, true), Buffer)

    self:set_buff_settings(buff_settings)

    self.buff_tracker = BuffTracker.new()

    return self
end

function Buffer:destroy()
    Role.destroy(self)

    self.buff_tracker:destroy()
end

function Buffer:on_add()
    Role.on_add(self)
end

function Buffer:set_buff_settings(buff_settings)
    for gambit in buff_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition.editable = false
            gambit:addCondition(condition)
        end
        if self:get_job() then
            gambit.conditions = gambit.conditions + self:get_job():get_conditions_for_ability(gambit:getAbility())
        end
    end
    self:set_gambit_settings(buff_settings)
end

function Buffer:get_default_conditions(gambit)
    local conditions = L{
        NotCondition.new(L{ HasBuffCondition.new(gambit:getAbility():get_status().en) }),
        NotCondition.new(L{ BuffConflictsCondition.new(gambit:getAbility():get_status().en)}),
        MinHitPointsPercentCondition.new(1),
    }
    if L(gambit:getAbility():get_valid_targets()) ~= L{ 'Self' } then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end
    if gambit:getAbility().get_job_abilities then
        for job_ability_name in gambit:getAbility():get_job_abilities():it() do
            conditions:append(JobAbilityRecastReadyCondition.new(job_ability_name))
        end
    end
    return conditions
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:get_type()
    return "buffer"
end

function Buffer:get_cooldown()
    return 5
end

function Buffer:get_localized_name()
    return "Buffing"
end

function Buffer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Buffer