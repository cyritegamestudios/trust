local cure_util = require('cylibs/util/cure_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local CureAction = require('cylibs/actions/cure')
local HealerTracker = require('cylibs/analytics/trackers/healer_tracker')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')

local Healer = setmetatable({}, {__index = Role })
Healer.__index = Healer
Healer.__class = "Healer"

state.AutoHealMode = M{['description'] = 'Heal Player and Party', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "You can count on me to heal the party.")
state.AutoHealMode:set_description('Emergency', "Okay, I'll only heal when you're in a pinch.")

-------
-- Default initializer for a healer.
-- @tparam ActionQueue action_queue Shared action queue
-- @tparam Job main_job Main job, used to specify cures spells/abilities
-- @treturn Healer A healer
function Healer.new(action_queue, main_job)
    local self = setmetatable(Role.new(action_queue), Healer)

    self.main_job = main_job
    self.last_cure_time = os.time()
    self.cure_delay = main_job:get_cure_delay()
    self.party_member_blacklist = L{}

    self.dispose_bag = DisposeBag.new()

    return self
end

function Healer:destroy()
    self.is_disposed = true

    self.dispose_bag:destroy()
end

function Healer:on_add()
    local on_party_member_added = function(p)
        self.dispose_bag:add(p:on_hp_change():addAction(function(p, hpp, max_hp)
            if state.AutoHealMode.value == 'Off' then
                return
            end
            if hpp > 0 then
                if hpp < 25 then
                    if p:get_mob() and p:get_mob().distance:sqrt() < 21 then
                        logger.notice(self.__class, 'on_hp_change', p:get_name(), hpp)
                        self:check_party_hp(self:get_job():get_cure_threshold(true))
                    end
                else
                    logger.notice(self.__class, 'on_hp_change', 'check_party_hp', hpp)
                    self:check_party_hp()
                end
            end
        end), p:on_hp_change())
    end

    self.dispose_bag:add(self:get_party():on_party_member_added():addAction(on_party_member_added), self:get_party():on_party_member_added())

    for party_member in self:get_party():get_party_members(true, 21):it() do
        on_party_member_added(party_member)
    end

    self.healer_tracker = HealerTracker.new(self)
    self.healer_tracker:monitor()

    self.dispose_bag:addAny(L{ self.healer_tracker })
end

function Healer:target_change(target_index)
    Role.target_change(self, target_index)
end

function Healer:tic(old_time, new_time)
    if state.AutoHealMode.value == 'Off'
            or (os.time() - self.last_cure_time) < self.cure_delay
            or self:get_party() == nil then
        return
    end

    self:check_party_hp()
end

-------
-- Checks the hp of party members and cures if needed.
-- @tparam number cure_threshold (optional) Cure threshold, defaults to self:get_cure_threshold()
function Healer:check_party_hp(cure_threshold)
    cure_threshold = cure_threshold or self:get_cure_threshold()

    logger.notice(self.__class, 'check_party_hp', cure_threshold)

    local party_members = self:get_valid_cure_targets(function(p)
        return p:get_hpp() <= cure_threshold -- for Afflatus Misery I think this should be 1 under cure threshold and others under 1.2x
    end):sort(function(p1, p2)
        return p1:get_hpp() < p2:get_hpp()
    end)
    party_members = self:get_cure_cluster(party_members)

    if #party_members >= self:get_job():get_aoe_threshold() then
        self:cure_party_members(party_members)
    else
        for party_member in party_members:it() do
            self:cure_party_member(party_member)
        end
    end
end

-------
-- Returns a cluster of party members within 10' of the first party member in the list.
-- @tparam list List of party members
-- @treturn list List of party members
function Healer:get_cure_cluster(party_members)
    if #party_members >= self:get_job():get_aoe_threshold() then
        if self:get_job().get_cure_cluster then
            return self:get_job():get_cure_cluster(party_members)
        else
            local spell_target = party_members[1]
            party_members = party_members:filter(function(party_member)
                local distance = geometry_util.distance(spell_target:get_mob(), party_member:get_mob())
                return distance < 10
            end)
        end
    end
    return party_members
end

-------
-- Returns all party members that are alive and in range.
-- @tparam function Filter to use on party members (optional)
-- @treturn list List of party members
function Healer:get_valid_cure_targets(filter)
    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return self:is_valid_cure_target(party_member) and filter(party_member)
    end)
    return party_members
end

-------
-- Returns whether a party member can be cured.
-- @tparam party_member PartyMember The party member
-- @treturn boolean True if the party member is a valid cure target
function Healer:is_valid_cure_target(party_member)
    return party_member:is_valid() and not S(self.party_member_blacklist):contains(party_member:get_name())
end

-------
-- Cures a party member. Cures may take higher priority than other actions depending upon how much hp is missing.
-- AutoHealMode must be set to Auto.
-- @tparam PartyMember party_member Party member to cure
function Healer:cure_party_member(party_member)
    if state.AutoHealMode.value == 'Off'
            or (os.time() - self.last_cure_time) < self.cure_delay
            or not party_member:is_alive() then
        return
    end

    logger.notice(self.__class, 'cure_party_member', party_member:get_name())

    local missing_hp = party_member:get_max_hp() - party_member:get_hp()

    local cure_spell_or_job_ability = self.main_job:get_cure_spell(missing_hp)
    if cure_spell_or_job_ability then
        logger.notice(self.__class, 'cure_party_member', party_member:get_name(), missing_hp, cure_spell_or_job_ability:get_name())

        self.last_cure_time = os.time()

        local cure_action = self:get_cure_action(cure_spell_or_job_ability, party_member)
        cure_action.identifier = self.__class..'cure_party_member'
        cure_action.priority = cure_util.get_cure_priority(party_member:get_hpp(), party_member:is_trust(), false)

        self.action_queue:push_action(cure_action, true)
    end
end

-------
-- Cures multiple party members with an aoe cure. Cures may take higher priority than other actions depending upon how
-- much hp is missing. AutoHealMode must be set to Auto.
-- @tparam list party_members List of party members to cure
function Healer:cure_party_members(party_members)
    if state.AutoHealMode.value == 'Off'
            or (os.time() - self.last_cure_time) < self.cure_delay then
        return
    end

    logger.notice(self.__class, 'cure_party_members', L(party_members:map(function(p) return p:get_name() end)):tostring())

    local max_missing_hp = 0
    local spell_target = nil
    local is_trust_only = true

    for party_member in party_members:it() do
        local new_max_missing_hp = party_member:get_max_hp() - party_member:get_hp()
        if new_max_missing_hp > max_missing_hp then
            spell_target = party_member
            max_missing_hp = new_max_missing_hp
            if not party_member:is_trust() then
                is_trust_only = false
            end
        end
    end

    local cure_spell_or_job_ability = self.main_job:get_aoe_cure_spell(max_missing_hp)
    if cure_spell_or_job_ability and spell_target then
        local target_override = cure_spell_or_job_ability:get_target(true)
        if target_override then
            spell_target = self:get_party():get_party_member(target_override.id)
        end

        logger.notice(self.__class, 'cure_party_members', spell_target:get_name(), max_missing_hp, cure_spell_or_job_ability:get_name())

        self.last_cure_time = os.time()

        local cure_action = self:get_cure_action(cure_spell_or_job_ability, spell_target)
        cure_action.identifier = self.__class..'cure_party_members'
        cure_action.priority = cure_util.get_cure_priority(spell_target:get_hpp(), is_trust_only, true)

        self.action_queue:push_action(cure_action, true)
    end
end

function Healer:get_cure_action(spell_or_job_ability, party_member)
    if spell_or_job_ability then
        if spell_or_job_ability.__type == "Spell" then
            local cure_action = spell_or_job_ability:to_action(party_member:get_mob().index, self:get_player())
            return cure_action
        else
            local cure_action = spell_or_job_ability:to_action(party_member:get_mob().index)
            return cure_action
        end
    end
    logger.error(self.__class, 'get_cure_action', 'no cure action found')
    return nil
end

function Healer:get_cure_threshold()
    if state.AutoHealMode.value == 'Emergency' then
        return self.main_job:get_cure_threshold(true)
    else
        return self.main_job:get_cure_threshold(false)
    end
end

function Healer:allows_duplicates()
    return false
end

function Healer:get_type()
    return "healer"
end

function Healer:get_job()
    return self.main_job
end

function Healer:get_tracker()
    return self.healer_tracker
end

function Healer:set_party_member_blacklist(blacklist)
    self.party_member_blacklist = blacklist
end

function Healer:get_party_member_blacklist()
    return self.party_member_blacklist
end

return Healer