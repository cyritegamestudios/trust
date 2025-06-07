local Reacter = require('cylibs/trust/roles/reacter')
local Healer = setmetatable({}, {__index = Reacter })
Healer.__index = Healer

local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

state.AutoHealMode = M{['description'] = 'Heal Player and Party', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "Heal the party using the Default cure threshold.")
state.AutoHealMode:set_description('Emergency', "Heal the party using the Emergency cure threshold.")

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T heal_settings heal settings
-- @treturn Healer A healer role
function Healer.new(action_queue, heal_settings, job)
    local self = setmetatable(Reacter.new(action_queue, { Gambits = L{} }, nil, state.AutoHealMode), Healer)

    self.job = job
    self.dispose_bag = DisposeBag.new()

    self:set_heal_settings(heal_settings)

    return self
end

function Healer:destroy()
    Reacter.destroy(self)

    self.dispose_bag:destroy()
end

function Healer:on_add()
    Reacter.on_add(self)

end

function Healer:get_cooldown()
    if self.state_var.value == 'Auto' then
        return 0
    else
        return 2
    end
end

function Healer:allows_duplicates()
    return false
end

function Healer:get_type()
    return "healer"
end

function Healer:allows_multiple_actions()
    return false
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Healer:set_heal_settings(heal_settings)
    self.heal_settings = heal_settings

    local gambits = heal_settings.Gambits:map(function(gambit)
        return gambit:copy()
    end)
    for gambit in gambits:it() do
        gambit:getAbility():set_requires_all_job_abilities(false)

        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings({ Gambits = gambits })
end

function Healer:get_default_conditions(gambit)
    local conditions = L{
    }

    if L(gambit:getAbility():get_valid_targets()) ~= L{ 'Self' } then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end

    local ability_conditions = self.job:get_conditions_for_ability(gambit:getAbility())
    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

return Healer