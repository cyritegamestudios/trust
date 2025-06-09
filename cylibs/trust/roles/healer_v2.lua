local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HealerTracker = require('cylibs/analytics/trackers/healer_tracker')
local TargetNamesCondition = require('cylibs/conditions/target_names')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Healer = setmetatable({}, {__index = Gambiter })
Healer.__index = Healer

state.AutoHealMode = M{['description'] = 'Heal Player and Party', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "Heal the party using the Default cure threshold.")
state.AutoHealMode:set_description('Emergency', "Heal the party using the Emergency cure threshold.")

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T heal_settings heal settings
-- @treturn Healer A healer role
function Healer.new(action_queue, heal_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoHealMode }), Healer)

    self.job = job
    self.party_member_blacklist = L{}
    self.timer.timeInterval = self:get_cooldown()
    self.dispose_bag = DisposeBag.new()

    self:set_heal_settings(heal_settings)

    return self
end

function Healer:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Healer:on_add()
    Gambiter.on_add(self)

    self.healer_tracker = HealerTracker.new(self)
    self.healer_tracker:monitor()

    self.dispose_bag:addAny(L{ self.healer_tracker })
end

function Healer:get_cooldown()
    if state.AutoHealMode.value == 'Auto' then
        return 0.5
    else
        return 4 -- FIXME: for emergency, I can either do this or I can append a HPP < X% condition to each gambit when AutoHealMode changes to Emergency
    end
end

-- FIXME: this can actually work--just need to set priority of main vs sub job heals
function Healer:allows_duplicates()
    return false --return true
end

function Healer:get_type()
    return "healer"
end

function Healer:allows_multiple_actions()
    return false
end

function Healer:get_priority()
    if self.job:isMainJob() then
        return ActionPriority.medium
    end
    return ActionPriority.default
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Healer:set_heal_settings(heal_settings)
    self.heal_settings = heal_settings

    for gambit in heal_settings.Gambits:it() do
        if gambit:getAbility().set_requires_all_job_abilities ~= nil then
            gambit:getAbility():set_requires_all_job_abilities(false)
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

    self:set_gambit_settings(heal_settings)
end

function Healer:get_default_conditions(gambit)
    local conditions = L{
    }

    if self:get_party_member_blacklist():length() > 0 then
        conditions:append(NotCondition.new(L{ TargetNamesCondition.new(self:get_party_member_blacklist()) }))
    end

    if gambit:getAbilityTarget() == GambitTarget.TargetType.Ally then
        conditions:append(GambitCondition.new(MaxDistanceCondition.new(gambit:getAbility():get_range()), GambitTarget.TargetType.Ally))
    end

    local ability_conditions = (L{} + self.job:get_conditions_for_ability(gambit:getAbility()))

    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Healer:get_tracker()
    return self.healer_tracker
end

function Healer:set_party_member_blacklist(blacklist)
    self.party_member_blacklist = blacklist
    self:set_heal_settings(self.heal_settings)
end

function Healer:get_party_member_blacklist()
    return self.party_member_blacklist
end

return Healer