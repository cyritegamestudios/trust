local cure_util = require('cylibs/util/cure_util')
local DamageMemory = require('cylibs/battle/damage_memory')
local DisposeBag = require('cylibs/events/dispose_bag')
local CureAction = require('cylibs/actions/cure')
local HealerTracker = require('cylibs/analytics/trackers/healer_tracker')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')

local Healer = setmetatable({}, {__index = Role })
Healer.__index = Healer

state.AutoHealMode = M{['description'] = 'Auto Heal Mode', 'Auto', 'Emergency', 'Off'}
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
    self.damage_memory = DamageMemory.new(0)
    self.damage_memory:monitor()

    self.dispose_bag = DisposeBag.new()
    self.dispose_bag:addAny(L{ self.damage_memory })

    return self
end

function Healer:destroy()
    self.is_disposed = true

    self.dispose_bag:destroy()
end

function Healer:on_add()
    local on_party_member_added = function(p)
        self.dispose_bag:add(p:on_hp_change():addAction(function(p, hpp, max_hp)
            if hpp > 0 then
                if hpp < 25 then
                    if p:get_mob().distance:sqrt() < 21 then
                        self:check_party_hp(25)
                    end
                else
                    self:check_party_hp()
                end
            end
        end), p:on_hp_change())
    end

    self.dispose_bag:add(self:get_party():on_party_member_added():addAction(on_party_member_added), self:get_party():on_party_member_added())

    for party_member in self:get_party():get_party_members(true):it() do
        on_party_member_added(party_member)
    end

    self.healer_tracker = HealerTracker.new(self)
    self.healer_tracker:monitor()

    self.dispose_bag:addAny(L{ self.healer_tracker })
end

function Healer:target_change(target_index)
    Role.target_change(self, target_index)

    self.damage_memory:reset()
    self.damage_memory:target_change(target_index)
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

    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21
                and party_member:get_hpp() <= cure_threshold and party_member:is_alive()
    end):sort(function(p1, p2)
        return p1:get_hpp() < p2:get_hpp()
    end)

    if #party_members > 2 then
        local spell_target = party_members[1]
        party_members = party_members:filter(function(party_member)
            local distance = geometry_util.distance(spell_target:get_mob(), party_member:get_mob())
            return distance < 10
        end)
    end

    if #party_members > 2 then
        self:cure_party_members(party_members)
    else
        for party_member in party_members:it() do
            self:cure_party_member(party_member)
        end
    end
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

    local missing_hp = party_member:get_max_hp() - party_member:get_hp()

    local cure_spell_or_job_ability = self.main_job:get_cure_spell(missing_hp)
    if cure_spell_or_job_ability then
        self.last_cure_time = os.time()

        local cure_action = self:get_cure_action(cure_spell_or_job_ability, party_member)
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
        self.last_cure_time = os.time()

        local cure_action = self:get_cure_action(cure_spell_or_job_ability, spell_target)
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

return Healer