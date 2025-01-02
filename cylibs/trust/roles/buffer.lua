local BuffConflictsCondition = require('cylibs/conditions/buff_conflicts')
local BuffTracker = require('cylibs/battle/buff_tracker')
local res = require('resources')
local buff_util = require('cylibs/util/buff_util')
local spell_util = require('cylibs/util/spell_util')
local JobAbilityAction = require('cylibs/actions/job_ability')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')
local job_util = require('cylibs/util/job_util')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Buffer = setmetatable({}, {__index = Gambiter })
Buffer.__index = Buffer
Buffer.__class = "Buffer"

function Buffer.new(action_queue, buff_settings, state_var, buff_action_priority)
    local self = setmetatable(Gambiter.new(action_queue, {}, nil, state_var, true), Buffer)

    self:set_buff_settings(buff_settings)

    self.buff_tracker = BuffTracker.new()

    return self
end

function Buffer:destroy()
    Role.destroy(self)

    self.buff_tracker:destroy()
end

function Buffer:set_buff_settings(buff_settings)
    for gambit in buff_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition.editable = false
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings(buff_settings)
end

function Buffer:get_default_conditions(gambit)
    return L{
        MaxDistanceCondition.new(gambit:getAbility():get_range()),
        NotCondition.new(L{ HasBuffCondition.new(gambit:getAbility():get_status().en) }),
        NotCondition.new(L{ BuffConflictsCondition.new(gambit:getAbility():get_status().en)})
    }
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:get_type()
    return "buffer"
end

function Buffer:get_cooldown()
    return 3
end

function Buffer:get_localized_name()
    return "Buffing"
end

function Buffer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

--[[function Buffer:get_spell_target(spell)
    if spell:get_target() then
        local target = windower.ffxi.get_mob_by_target(spell:get_target())
        return target
    else
        return windower.ffxi.get_player()
    end
end]]

--[[function Buffer:range_check(spell)
    if spell:is_aoe() then
        return #self:get_party():get_party_members(true, spell:get_range()) >= math.min(self:get_party():num_party_members(), spell:num_targets_required())
    else
        return true
    end
end]]

--[[function Buffer:check_buffs()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)

    -- Job abilities
    if self.job_abilities_enabled then
        for job_ability in self.job_abilities:it() do
            local buff = buff_util.buff_for_job_ability(job_ability:get_job_ability_id())
            if buff and job_ability:isEnabled() and not buff_util.is_buff_active(buff.id, player_buff_ids)
                    and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
                if job_util.can_use_job_ability(job_ability:get_job_ability_name()) and self:main_job_check(job_ability) and self:conditions_check(job_ability, buff, windower.ffxi.get_player()) then
                    self.last_buff_time = os.time()
                    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability:get_job_ability_name()), true)
                    return
                end
            end
        end
    end

    if self:get_player():is_moving() then
       return
    end

    -- Spells (self buffs)
    if self.self_spells_enabled then
        logger.notice(self.__class, 'check_buffs', 'self_buffs')

        for spell in self.self_spells:it() do
            local buff = buff_util.buff_for_spell(spell:get_spell().id)
            if buff and spell:isEnabled() and not buff_util.is_buff_active(buff.id, player_buff_ids) and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids)
                    and spell_util.can_cast_spell(spell:get_spell().id) then
                if self:range_check(spell) then
                    local target = self:get_spell_target(spell)
                    if target and self:main_job_check(spell) and self:conditions_check(spell, buff, target) then
                        if self:cast_spell(spell, target.index) then
                            return
                        end
                    end
                else
                    self:get_party():add_to_chat(self:get_party():get_player(), "I can't cast "..spell:get_spell().en.." unless at least "..spell:num_targets_required().." party members are in range.", "buffer_party_member_out_of_range", 30)
                end
            end
        end
    end

    -- Spells (party buffs)
    if self.party_spells_enabled then
        for party_member in self:get_party():get_party_members(false, 21):it() do
            if party_member:is_alive() and not S(self.party_member_blacklist):contains(party_member:get_name()) then
                for spell in self.party_spells:it() do
                    local buff = buff_util.buff_for_spell(spell:get_spell().id)
                    if buff and spell:isEnabled() and not (party_member:has_buff(buff.id) or (party_member:is_trust() and self.buff_tracker:has_buff(party_member:get_mob().id, buff.id)))
                            and not (buff_util.conflicts_with_buffs(buff.id, party_member:get_buff_ids()))
                            and spell_util.can_cast_spell(spell:get_spell().id) then
                        local target = party_member:get_mob()
                        if target and self:main_job_check(spell) and self:conditions_check(spell, buff, target) then
                            if self:cast_spell(spell, target.index) then
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end]]



return Buffer