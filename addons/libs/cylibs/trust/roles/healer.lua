local cure_util = require('cylibs/util/cure_util')
local DamageMemory = require('cylibs/battle/damage_memory')
local AuraTracker = require('cylibs/battle/aura_tracker')
local StatusRemovalAction = require('cylibs/actions/status_removal')
local CureAction = require('cylibs/actions/cure')

local Healer = setmetatable({}, {__index = Role })
Healer.__index = Healer

state.AutoHealMode = M{['description'] = 'Auto Heal Mode', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "You can count on me to heal the party.")
state.AutoHealMode:set_description('Emergency', "Okay, I'll only heal when you're in a pinch.")

state.AutoDetectAuraMode = M{['description'] = 'Auto Detect Aura Mode', 'Off', 'Auto'}
state.AutoDetectAuraMode:set_description('Auto', "Okay, I'll try not to remove status effects caused by auras.")

state.AutoBarSpellMode = M{['description'] = 'Auto Barspell Mode', 'Off', 'Manual', 'Auto'}
state.AutoBarSpellMode:set_description('Manual', "Okay, I'll make sure to remember the last barspell you tell me to cast.")
state.AutoBarSpellMode:set_description('Auto', "Okay, I'll try to figure out which barspell to cast on my own.")

-------
-- Default initializer for a healer.
-- @tparam ActionQueue action_queue Shared action queue
-- @tparam Job main_job Main job, used to specify cures spells/abilities
-- @treturn Healer A healer
function Healer.new(action_queue, main_job)
    local self = setmetatable(Role.new(action_queue), Healer)

    self.action_events = {}
    self.main_job = main_job
    self.last_cure_time = os.time()
    self.damage_memory = DamageMemory.new(0)
    self.damage_memory:monitor()
    self.aura_list = S{}

    return self
end

function Healer:destroy()
    self.is_disposed = true
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    if self.on_party_member_hp_change_id then
        self:get_party():on_party_member_hp_change():removeAction(self.on_party_member_hp_change_id)
    end

    if self.aura_tracker then
        self.aura_tracker:destroy()
    end

    self.damage_memory:destroy()
end

function Healer:on_add()
    self.aura_tracker = AuraTracker.new(buff_util.debuffs_for_auras(), self:get_party())

    self.on_party_member_hp_change_id = self:get_party():on_party_member_hp_change():addAction(
            function (p, hpp, max_hp)
                if hpp > 0 then
                    if hpp < 25 then
                        self:cure_party_member(p)
                    else
                        self:check_party_hp()
                    end
                end
            end)

    for party_member in self:get_party():get_party_members(false):it() do
        party_member:on_gain_debuff():addAction(
            function (p, debuff_id)
                self:remove_status_effect(L{p}, debuff_id)
            end)
    end
end

function Healer:target_change(target_index)
    Role.target_change(self, target_index)

    self.damage_memory:reset()
    self.damage_memory:target_change(target_index)

    self.aura_tracker:reset()
end

function Healer:tic(old_time, new_time)
    if state.AutoHealMode.value == 'Off'
            or (os.time() - self.last_cure_time) < 2
            or self:get_party() == nil then
        return
    end

    self.aura_tracker:tic(old_time, new_time)

    self:check_party_hp()
    self:check_party_status_effects()
end

-------
-- Checks the hp of party members and cures if needed.
function Healer:check_party_hp()
    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21
                and party_member:get_hpp() <= self:get_cure_threshold() and party_member:is_alive()
    end):sort(function(p1, p2)
        return p1:get_hpp() < p2:get_hpp()
    end)

    if #party_members > 2 then
        self:cure_party_members(party_members)
    else
        for party_member in party_members:it() do
            self:cure_party_member(party_member)
        end
    end
end

-------
-- Checks the status effects of party members and removes them if needed.
function Healer:check_party_status_effects()
    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21
                and #party_member:get_debuffs() > 0 and party_member:is_alive()
    end)
    for party_member in party_members:it() do
        local debuff_ids = party_member:get_debuffs():filter(function(debuff_id) return self.main_job:get_status_removal_spell(debuff_id, 1) ~= nil  end)
        if debuff_ids:length() > 0 then
            local debuff_id = res.buffs:with('enl', party_member:get_debuffs()[1]).id
            local targets = party_members:filter(function(p) return p:has_debuff(debuff_id) end)
            self:remove_status_effect(targets, debuff_id)
            return
        end
    end
end

-------
-- Cures a party member. Cures may take higher priority than other actions depending upon how much hp is missing.
-- AutoHealMode must be set to Auto.
-- @tparam PartyMember party_member Party member to cure
function Healer:cure_party_member(party_member)
    if state.AutoHealMode.value == 'Off'
            or (os.time() - self.last_cure_time) < 2
            or not party_member:is_alive() then
        return
    end

    local missing_hp = party_member:get_max_hp() - party_member:get_hp()

    local cure_spell = self.main_job:get_cure_spell(missing_hp)
    if cure_spell then
        self.last_cure_time = os.time()

        local actions = L{}
        for job_ability_name in cure_spell:get_job_abilities():it() do
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
            actions:append(WaitAction.new(0, 0, 0, 1))
        end

        actions:append(CureAction.new(0, 0, 0, party_member, 90, self.main_job, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 1))

        local cure_action = SequenceAction.new(actions, 'healer_cure_'..party_member:get_mob().id)
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
            or (os.time() - self.last_cure_time) < 2 then
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

    local cure_spell = self.main_job:get_aoe_cure_spell(max_missing_hp)
    if cure_spell and spell_target then
        self.last_cure_time = os.time()

        local actions = L{}
        for job_ability_name in cure_spell:get_job_abilities():it() do
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
            actions:append(WaitAction.new(0, 0, 0, 1))
        end

        actions:append(SpellAction.new(0, 0, 0, cure_spell:get_spell().id, spell_target:get_mob().index, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 1))

        local cure_action = SequenceAction.new(actions, 'healer_cure_'..spell_target:get_mob().id)
        cure_action.priority = cure_util.get_cure_priority(spell_target:get_hpp(), is_trust_only, true)

        self.action_queue:push_action(cure_action, true)
    end
end

-------
-- Removes a status effect from a party member. AutoHealMode must be set to Auto.
-- @tparam list party_members Party members to remove status effect from
-- @tparam number debuff_id Debuff id of status effect (see buffs.lua)
function Healer:remove_status_effect(party_members, debuff_id)
    if state.AutoHealMode.value == 'Off' or (os.time() - self.last_cure_time) < 3 then
        return
    end
    if state.AutoDetectAuraMode.value ~= 'Off' and self.aura_tracker:get_aura_probability(debuff_id) >= 75 then
        return
    end
    local status_removal_spell = self.main_job:get_status_removal_spell(debuff_id, party_members:length())
    if status_removal_spell then
        self.last_cure_time = os.time()

        if status_removal_spell:get_job_abilities():length() > 0 then
            local job_ability_actions = L{}
            for job_ability_name in status_removal_spell:get_job_abilities():it() do
                job_ability_actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                job_ability_actions:append(WaitAction.new(0, 0, 0, 1))
            end
            local job_ability_action =  SequenceAction.new(job_ability_actions, 'healer_status_removal_'..party_members[1]:get_mob().id..'_'..debuff_id..'_job_abilities')
            job_ability_action.priority = cure_util.get_status_removal_priority(debuff_id, party_members[1]:is_trust())

            self.action_queue:push_action(job_ability_action, true)
        end

        local actions = L{}

        local spell_action = StatusRemovalAction.new(0, 0, 0, status_removal_spell:get_spell().id, party_members[1]:get_mob().index, debuff_id, self:get_player())
        spell_action:on_status_removal_no_effect():addAction(function(_, spell_id, target_id, debuff_id)
            self.aura_tracker:record_status_effect_removal(spell_id, target_id, debuff_id)
        end)

        actions:append(spell_action)
        actions:append(WaitAction.new(0, 0, 0, 1))

        local status_removal_action = SequenceAction.new(actions, 'healer_status_removal_'..party_members[1]:get_mob().id..'_'..debuff_id)
        status_removal_action.priority = cure_util.get_status_removal_priority(debuff_id, party_members[1]:is_trust())

        self.action_queue:push_action(status_removal_action, true)
    end
end



function Healer:check_barspells()
    if state.AutoBarSpellMode.value == 'Off' then
        return
    end
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

return Healer