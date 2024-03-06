local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local AuraTracker = require('cylibs/battle/aura_tracker')
local DisposeBag = require('cylibs/events/dispose_bag')
local logger = require('cylibs/logger/logger')
local StatusRemovalAction = require('cylibs/actions/status_removal')

local StatusRemover = setmetatable({}, {__index = Role })
StatusRemover.__index = StatusRemover

state.AutoStatusRemovalMode = M{['description'] = 'Auto Status Removal Mode', 'Auto', 'Off'}
state.AutoStatusRemovalMode:set_description('Auto', "Okay, I'll remove status effects.")

state.AutoDetectAuraMode = M{['description'] = 'Auto Detect Aura Mode', 'Off', 'Auto'}
state.AutoDetectAuraMode:set_description('Auto', "Okay, I'll try not to remove status effects caused by auras.")

-------
-- Default initializer for a status remover.
-- @tparam ActionQueue action_queue Shared action queue
-- @tparam Job main_job Main job, used to specify status removal spells
-- @treturn StatusRemover A status remover
function StatusRemover.new(action_queue, main_job)
    local self = setmetatable(Role.new(action_queue), StatusRemover)

    self.action_events = {}
    self.main_job = main_job
    self.last_status_removal_time = os.time()
    self.status_removal_delay = main_job:get_status_removal_delay()
    self.aura_list = S{}
    self.dispose_bag = DisposeBag.new()

    return self
end

function StatusRemover:destroy()
    self.is_disposed = true

    self.dispose_bag:destroy()

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function StatusRemover:on_add()
    self.aura_tracker = AuraTracker.new(buff_util.debuffs_for_auras(), self:get_party())

    self.dispose_bag:addAny(L{ self.aura_tracker })

    for party_member in self:get_party():get_party_members(true):it() do
        self.dispose_bag:add(party_member:on_gain_debuff():addAction(
            function (p, debuff_id)
                self:remove_status_effect(L{p}, debuff_id)
            end), party_member:on_gain_debuff())
    end
end

function StatusRemover:target_change(target_index)
    Role.target_change(self, target_index)

    self.aura_tracker:reset()
end

function StatusRemover:tic(old_time, new_time)
    if state.AutoStatusRemovalMode.value == 'Off'
            or (os.time() - self.last_status_removal_time) < self.status_removal_delay
            or self:get_party() == nil then
        return
    end

    self.aura_tracker:tic(old_time, new_time)

    self:check_party_status_effects()
end

-------
-- Checks the status effects of party members and removes them if needed.
function StatusRemover:check_party_status_effects()
    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21
                and #party_member:get_debuffs() > 0 and party_member:is_alive()
    end)
    for party_member in party_members:it() do
        local debuff_ids = party_member:get_debuff_ids():filter(function(debuff_id) return self.main_job:get_status_removal_spell(debuff_id, 1) ~= nil  end)
        if debuff_ids:length() > 0 then
            local debuff_id = res.buffs:with('enl', party_member:get_debuffs()[1]).id
            local targets = party_members:filter(function(p) return p:has_debuff(debuff_id) end)
            self:remove_status_effect(targets, debuff_id)
            return
        end
    end
end

-------
-- Removes a status effect from a party member. AutoStatusRemovalMode must be set to Auto.
-- @tparam list party_members Party members to remove status effect from
-- @tparam number debuff_id Debuff id of status effect (see buffs.lua)
function StatusRemover:remove_status_effect(party_members, debuff_id)
    if state.AutoStatusRemovalMode.value == 'Off' or (os.time() - self.last_status_removal_time) < 3 then
        return
    end
    if state.AutoDetectAuraMode.value ~= 'Off' and self.aura_tracker:get_aura_probability(debuff_id) >= 75 then
        logger.notice("Detected", res.buffs[debuff_id].en, "aura.")
        return
    end
    local status_removal_spell = self.main_job:get_status_removal_spell(debuff_id, party_members:length())
    if status_removal_spell then
        self.last_status_removal_time = os.time()

        if status_removal_spell:get_job_abilities():length() > 0 then
            local job_ability_actions = L{}
            for job_ability_name in status_removal_spell:get_job_abilities():it() do
                job_ability_actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                job_ability_actions:append(WaitAction.new(0, 0, 0, 1))
            end
            local job_ability_action =  SequenceAction.new(job_ability_actions, 'status_removal_'..party_members[1]:get_mob().id..'_'..debuff_id..'_job_abilities')
            job_ability_action.priority = cure_util.get_status_removal_priority(debuff_id, party_members[1]:is_trust())

            self.action_queue:push_action(job_ability_action, true)
        end

        local actions = L{}

        local spell_target = party_members[1]
        if not status_removal_spell:get_spell().targets:contains('Party') then
            spell_target = self:get_party():get_player()
        end

        local spell_action = StatusRemovalAction.new(0, 0, 0, status_removal_spell:get_spell().id, spell_target:get_mob().index, debuff_id, self:get_player())
        spell_action:on_status_removal_no_effect():addAction(function(_, spell_id, target_id, debuff_id)
            self.aura_tracker:record_status_effect_removal(spell_id, target_id, debuff_id)
        end)

        actions:append(spell_action)
        actions:append(WaitAction.new(0, 0, 0, 1))

        local status_removal_action = SequenceAction.new(actions, 'healer_status_removal_'..spell_target:get_id()..'_'..debuff_id)
        status_removal_action.priority = cure_util.get_status_removal_priority(debuff_id, spell_target:is_trust())

        self.action_queue:push_action(status_removal_action, true)

        logger.notice("Removing", res.buffs[debuff_id].en, "from", spell_target:get_name())
    else
        logger.error("No status removal spell found for", res.buffs[debuff_id].en, "effect on", party_members[1]:get_name())
    end
end

function StatusRemover:allows_duplicates()
    return false
end

function StatusRemover:get_type()
    return "statusremover"
end

return StatusRemover