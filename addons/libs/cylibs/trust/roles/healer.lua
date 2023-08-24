local cure_util = require('cylibs/util/cure_util')
local DamageMemory = require('cylibs/battle/damage_memory')
local AuraTracker = require('cylibs/battle/aura_tracker')
local CureAction = require('cylibs/actions/cure')

local Healer = setmetatable({}, {__index = Role })
Healer.__index = Healer

state.AutoHealMode = M{['description'] = 'Auto Heal Mode', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "You can count on me to heal the party.")
state.AutoHealMode:set_description('Emergency', "Okay, I'll only heal when you're in a pinch.")

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
    self.cure_delay = main_job:get_cure_delay()
    self.damage_memory = DamageMemory.new(0)
    self.damage_memory:monitor()

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

    self.damage_memory:destroy()
end

function Healer:on_add()
    self.on_party_member_hp_change_id = self:get_party():on_party_member_hp_change():addAction(
            function (p, hpp, max_hp)
                if hpp > 0 then
                    if hpp < 25 then
                        if p:get_mob().distance:sqrt() < 21 then
                            self:cure_party_member(p)
                        end
                    else
                        self:check_party_hp()
                    end
                end
            end)
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

    local cure_spell = self.main_job:get_cure_spell(missing_hp)
    if cure_spell then
        self.last_cure_time = os.time()

        local actions = L{}
        for job_ability_name in cure_spell:get_job_abilities():it() do
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
            actions:append(WaitAction.new(0, 0, 0, 1))
        end

        actions:append(CureAction.new(0, 0, 0, party_member, 90, cure_spell:get_spell().mp_cost, self.main_job, self:get_player()))
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