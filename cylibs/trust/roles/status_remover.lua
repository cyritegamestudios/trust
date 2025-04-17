local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local AuraTracker = require('cylibs/battle/aura_tracker')
local DisposeBag = require('cylibs/events/dispose_bag')
local logger = require('cylibs/logger/logger')
local StatusRemovalAction = require('cylibs/actions/status_removal')

local StatusRemover = setmetatable({}, {__index = Role })
StatusRemover.__index = StatusRemover
StatusRemover.__class = "StatusRemover"

state.AutoStatusRemovalMode = M{['description'] = 'Remove Status Ailments', 'Auto', 'Off'}
state.AutoStatusRemovalMode:set_description('Auto', "Remove status effects from self and party members.")

state.AutoDetectAuraMode = M{['description'] = 'Detect Auras', 'Off', 'Auto'}
state.AutoDetectAuraMode:set_description('Auto', "Avoid removing status effects caused by auras.")

-------
-- Default initializer for a status remover.
-- @tparam ActionQueue action_queue Shared action queue
-- @tparam Job main_job Main job, used to specify status removal spells
-- @treturn StatusRemover A status remover
function StatusRemover.new(action_queue, main_job)
    local self = setmetatable(Role.new(action_queue), StatusRemover)

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
end

function StatusRemover:on_add()
    self.aura_tracker = AuraTracker.new(buff_util.debuffs_for_auras(), self:get_party())

    self.dispose_bag:addAny(L{ self.aura_tracker })

    local monitor_party_member = function(party_member)
        self.dispose_bag:add(party_member:on_gain_debuff():addAction(
            function (p, debuff_id)
                if party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21 and debuff_id ~= 0 then
                    self:remove_status_effect(L{p}, debuff_id)
                end
            end), party_member:on_gain_debuff())
    end

    self.dispose_bag:add(self:get_party():on_party_member_added():addAction(function(party_member)
        monitor_party_member(party_member)
    end), self:get_party():on_party_member_added())

    for party_member in self:get_party():get_party_members(true):it() do
        monitor_party_member(party_member)
    end

    self.dispose_bag:add(WindowerEvents.StatusRemoval.NoEffect:addAction(function(spell_id, target_id, debuff_id)
        self.aura_tracker:record_status_effect_removal(spell_id, target_id, debuff_id)
    end), WindowerEvents.StatusRemoval.NoEffect)
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
    logger.notice(self.__class, 'check_party_status_effects')

    local party_members = self:get_party():get_party_members(true, 21):filter(function(party_member)
        return party_member:get_mob() and party_member:get_mob().distance:sqrt() < 21
                and #party_member:get_debuffs() > 0
    end)
    for party_member in party_members:it() do
        local debuff_ids = party_member:get_debuff_ids():filter(function(debuff_id)
            local spell = self.main_job:get_status_removal_spell(debuff_id, 1)
            return spell and Condition.check_conditions(spell:get_conditions(), party_member:get_mob().index)
        end)
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
    if state.AutoStatusRemovalMode.value == 'Off' or (os.time() - self.last_status_removal_time) < 3 or party_members:length() == 0 then
        return
    end
    if state.AutoDetectAuraMode.value ~= 'Off' and self.aura_tracker:get_aura_probability(debuff_id) >= 75 then
        logger.notice(self.__class, 'remove_status_effect', 'detected aura', res.buffs[debuff_id].en)
        return
    end

    local status_removal_spell_or_ability = self.main_job:get_status_removal_spell(debuff_id, party_members:length())
    if status_removal_spell_or_ability then
        self.last_status_removal_time = os.time()

        local target = party_members[1]

        if S{ 'Party', 'Corpse' }:intersection(S(status_removal_spell_or_ability:get_valid_targets())):length() <= 0 then
            target = self:get_party():get_player()
        end

        local status_removal_action = status_removal_spell_or_ability:to_action(target:get_mob().index, self:get_player())
        status_removal_action:add_condition(HasDebuffCondition.new(buff_util.buff_name(debuff_id), target:get_mob().index))

        local actions = L{ status_removal_action, WaitAction.new(0, 0, 0, 1) }

        local status_removal_action = SequenceAction.new(actions, 'healer_status_removal_'..target:get_id()..'_'..debuff_id)
        status_removal_action.priority = cure_util.get_status_removal_priority(debuff_id, target:is_trust())

        self.action_queue:push_action(status_removal_action, true)

        logger.notice(self.__class, 'remove_status_effect', res.buffs[debuff_id].en, target:get_name(), #party_members, status_removal_spell_or_ability:get_name())
    else
        logger.notice(self.__class, 'remove_status_effect', res.buffs[debuff_id].en, 'no spell found')
    end
end

function StatusRemover:allows_duplicates()
    return false
end

function StatusRemover:get_type()
    return "statusremover"
end

return StatusRemover