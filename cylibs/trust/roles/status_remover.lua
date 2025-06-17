local buff_util = require('cylibs/util/buff_util')
local AuraTracker = require('cylibs/battle/aura_tracker')
local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local StatusRemovalAction = require('cylibs/actions/status_removal')
local TargetNamesCondition = require('cylibs/conditions/target_names')

local Gambiter = require('cylibs/trust/roles/gambiter')
local StatusRemover = setmetatable({}, {__index = Gambiter })
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
function StatusRemover.new(action_queue, status_removal_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoStatusRemovalMode }), StatusRemover)

    self.job = job
    self.party_member_blacklist = L{}
    self.timer.timeInterval = 1.0
    self.aura_list = S{}
    self.dispose_bag = DisposeBag.new()

    self:set_status_removal_settings(status_removal_settings)

    --local self = setmetatable(Role.new(action_queue), StatusRemover)

    --self.main_job = main_job
    --self.last_status_removal_time = os.time()
    --self.status_removal_delay = 1--main_job:get_status_removal_delay()

    --self.dispose_bag = DisposeBag.new()

    return self
end

function StatusRemover:destroy()
    self.is_disposed = true

    self.dispose_bag:destroy()
end

function StatusRemover:on_add()
    self.aura_tracker = AuraTracker.new(buff_util.debuffs_for_auras(), self:get_party())

    self.dispose_bag:addAny(L{ self.aura_tracker })

    self.dispose_bag:add(WindowerEvents.StatusRemoval.NoEffect:addAction(function(spell_id, target_id, debuff_id)
        self.aura_tracker:record_status_effect_removal(spell_id, target_id, debuff_id)
    end), WindowerEvents.StatusRemoval.NoEffect)
end

function StatusRemover:target_change(target_index)
    Role.target_change(self, target_index)

    self.aura_tracker:reset()
end

function StatusRemover:get_cooldown()
    return 1.0
end

function StatusRemover:allows_duplicates()
    return false
end

function StatusRemover:get_type()
    return "statusremover"
end

function StatusRemover:allows_multiple_actions()
    return false
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function StatusRemover:set_status_removal_settings(status_removal_settings)
    self.status_removal_settings = status_removal_settings
    self.blacklist = status_removal_settings.Blacklist

    for gambit in status_removal_settings.Gambits:it() do
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

    self:set_gambit_settings(status_removal_settings)
end

function StatusRemover:get_default_conditions(gambit)
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

function StatusRemover:set_party_member_blacklist(blacklist)
    self.party_member_blacklist = blacklist
    self:set_status_removal_settings(self.status_removal_settings)
end

function StatusRemover:get_party_member_blacklist()
    return self.party_member_blacklist
end



--[[function StatusRemover:tic(old_time, new_time)
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
end]]

return StatusRemover