local BuffConflictsCondition = require('cylibs/conditions/buff_conflicts')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasStatusEffectCondition = require('cylibs/conditions/has_status_effect')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Buffer = setmetatable({}, {__index = Gambiter })
Buffer.__index = Buffer
Buffer.__class = "Buffer"

function Buffer.new(action_queue, buff_settings, state_var, job)
    local self = setmetatable(Gambiter.new(action_queue, {}, state_var or state.AutoBuffMode), Buffer)

    self.job = job

    self:set_buff_settings(buff_settings)

    return self
end

function Buffer:destroy()
    Gambiter.destroy(self)
end

function Buffer:set_buff_settings(buff_settings)
    for gambit in buff_settings.Gambits:it() do
        if gambit:getAbility().__type == Buff.__type then
            gambit:getAbility():reload()
        end
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings(buff_settings)
end

function Buffer:get_default_conditions(gambit)
    local conditions = L{
        NotCondition.new(L{ HasStatusEffectCondition.new(gambit:getAbility():get_status().id) }),
        NotCondition.new(L{ BuffConflictsCondition.new(gambit:getAbility():get_status().en)}),
        MinHitPointsPercentCondition.new(1),
    }
    if gambit:getAbilityTarget() ~= GambitTarget.TargetType.Self then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:allows_multiple_actions()
    return false
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