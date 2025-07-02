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

    return self
end

function StatusRemover:destroy()
    Gambiter.destroy(self)

    self.is_disposed = true

    self.dispose_bag:destroy()
end

function StatusRemover:on_add()
    Gambiter.on_add(self)

    self.aura_tracker = AuraTracker.new(buff_util.debuffs_for_auras(), self:get_party())

    self.dispose_bag:addAny(L{ self.aura_tracker })

    self.dispose_bag:add(WindowerEvents.StatusRemoval.NoEffect:addAction(function(spell_id, target_id, debuff_id)
        self.aura_tracker:record_status_effect_removal(spell_id, target_id, debuff_id)
    end), WindowerEvents.StatusRemoval.NoEffect)
end

function StatusRemover:target_change(target_index)
    Gambiter.target_change(self, target_index)

    self.aura_tracker:reset()
end

function StatusRemover:get_cooldown()
    return 1.0
end

function StatusRemover:get_priority()
    return ActionPriority.high
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

return StatusRemover