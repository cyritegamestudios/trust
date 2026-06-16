local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HealerTracker = require('cylibs/analytics/trackers/healer_tracker')
local TargetNamesCondition = require('cylibs/conditions/target_names')
local Timer = require('cylibs/util/timers/timer')

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
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoHealMode }, heal_settings.IncludeAlliance == true), Healer)

    self.job = job
    self.party_member_blacklist = L{}
    self.timer.timeInterval = 0.5
    self.is_dirty = false
    self.dispose_bag = DisposeBag.new()
    self.party_member_dispose_bags = {}

    self:set_heal_settings(heal_settings)

    return self
end

function Healer:destroy()
    Gambiter.destroy(self)

    for _, bag in pairs(self.party_member_dispose_bags) do
        bag:destroy()
    end
    self.party_member_dispose_bags = {}
    self.dispose_bag:destroy()
end

function Healer:on_add()
    Gambiter.on_add(self)

    self.healer_tracker = HealerTracker.new(self)
    self.healer_tracker:monitor()

    self.dispose_bag:addAny(L{ self.healer_tracker })

    local on_party_member_added = function(p)
        local member_id = p:get_id()
        if self.party_member_dispose_bags[member_id] then
            self.party_member_dispose_bags[member_id]:destroy()
        end
        local member_dispose_bag = DisposeBag.new()
        member_dispose_bag:add(p:on_hp_change():addAction(function(p, hpp, max_hp)
            if state.AutoHealMode.value == 'Off' then
                return
            end
            if hpp > 0 then
                self.is_dirty = true
            end
        end), p:on_hp_change())
        self.party_member_dispose_bags[member_id] = member_dispose_bag
    end

    local on_party_member_removed = function(p)
        local member_id = p:get_id()
        if self.party_member_dispose_bags[member_id] then
            self.party_member_dispose_bags[member_id]:destroy()
            self.party_member_dispose_bags[member_id] = nil
        end
    end

    self.dispose_bag:add(self:get_party():on_party_member_added():addAction(on_party_member_added), self:get_party():on_party_member_added())
    self.dispose_bag:add(self:get_party():on_party_member_removed():addAction(on_party_member_removed), self:get_party():on_party_member_removed())

    for party_member in self:get_party():get_party_members(true, 21):it() do
        on_party_member_added(party_member)
    end

    self.on_event_timer = Timer.scheduledTimer(0.1)

    self.dispose_bag:add(self.on_event_timer:onTimeChange():addAction(function(_)
        if not self:is_enabled() or not self.is_dirty then
            return
        end
        self.is_dirty = false
        self:check_gambits(nil, nil, true)
    end, self:get_priority() or ActionPriority.default, self:get_type()), self.on_event_timer:onTimeChange())
    self.dispose_bag:addAny(L{ self.on_event_timer })

    self.on_event_timer:start()
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
    return true
end

function Healer:get_priority()
    if self.job:isMainJob() then
        return ActionPriority.highest
    end
    return ActionPriority.default
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Healer:set_heal_settings(heal_settings)
    self.heal_settings = heal_settings
    self.include_alliance = heal_settings.IncludeAlliance == true
    self.party_member_blacklist = heal_settings.Blacklist or L{}

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

        if gambit:getAbilityTarget() == GambitTarget.TargetType.Ally then
            gambit:setPriorityComparator(function(a, b) return a:get_hpp() < b:get_hpp() end)
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
    self.heal_settings.Blacklist = blacklist or L{}
    self:set_heal_settings(self.heal_settings)
end

function Healer:get_party_member_blacklist()
    return self.party_member_blacklist
end

return Healer
