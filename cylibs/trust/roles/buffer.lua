local BuffTracker = require('cylibs/battle/buff_tracker')
local res = require('resources')
local buff_util = require('cylibs/util/buff_util')
local spell_util = require('cylibs/util/spell_util')
local JobAbilityAction = require('cylibs/actions/job_ability')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')
local job_util = require('cylibs/util/job_util')

local Buffer = setmetatable({}, {__index = Role })
Buffer.__index = Buffer
Buffer.__class = "Buffer"

function Buffer.new(action_queue, self_buffs, party_buffs, state_var, buff_action_priority)
    local self = setmetatable(Role.new(action_queue), Buffer)

    self:set_self_buffs(self_buffs)
    self:set_party_buffs(party_buffs)

    self.state_var = state_var or state.AutoBuffMode
    self.buff_action_priority = buff_action_priority or ActionPriority.default
    self.buff_tracker = BuffTracker.new()
    self.last_buff_time = os.time()

    return self
end

function Buffer:destroy()
    Role.destroy(self)

    self.buff_tracker:destroy()
end

function Buffer:on_add()
    Role.on_add(self)

    if self.party_spells_enabled then
        self.buff_tracker:monitor()
    end

    if not self.job_abilities:empty() then
        self.job_abilities_enabled = true
    end
    if not self.self_spells:empty() then
        self.self_spells_enabled = true
    end
    if not self.party_spells:empty() then
        self.party_spells_enabled = true
    end
end

function Buffer:target_change(target_index)
    Role.target_change(self, target_index)
end

function Buffer:tic(_, _)
    if self.state_var.value == 'Off'
            or (os.time() - self.last_buff_time) < 8 then
        return
    end

    self:check_buffs()
end

function Buffer:get_spell_target(spell)
    if spell:get_target() then
        local target = windower.ffxi.get_mob_by_target(spell:get_target())
        return target
    else
        return windower.ffxi.get_player()
    end
end

function Buffer:range_check(spell)
    if spell:is_aoe() then
        return #self:get_party():get_party_members(true, spell:get_range()) >= math.min(self:get_party():num_party_members(), spell:num_targets_required())
    else
        return true
    end
end

function Buffer:conditions_check(spell, buff, target)
    if target == nil then
        return false
    end
    local conditions = L{
        MaxDistanceCondition.new(spell:get_range(), target.index),
        NotCondition.new(L{ HasBuffCondition.new(buff.name, target.index) })
    }:extend(spell:get_conditions()):filter(function(condition)
        if condition.__type == MainJobCondition.__type then
            return target.id == windower.ffxi.get_player().id
        end
        return true
    end)
    for condition in conditions:it() do
        if not condition:is_satisfied(target.index) then
            return false
        end
    end
    return true
end

function Buffer:check_buffs()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    --[[local player = self:get_party():get_player()

    local all_abilities = self.job_abilities + self.self_spells

    for ability in all_abilities:it() do
        if ability:isEnabled() then
            local buff = buff_util.buff_for(ability:get_ability_id())
            if buff and not buff_util.conflicts_with_buffs(buff.id, player:get_buff_ids()) then
                if self:conditions_check(ability, buff, player:get_mob()) then
                    self.last_buff_time = os.time()
                    self.action_queue:push_action(ability:to_action(player:get_mob().index, self:get_player(), ability:get_job_abilities()))
                    return
                end
            end
        end
    end]]

    -- Job abilities
    if self.job_abilities_enabled then
        for job_ability in self.job_abilities:it() do
            local buff = buff_util.buff_for_job_ability(job_ability:get_job_ability_id())
            if buff and job_ability:isEnabled() and not buff_util.is_buff_active(buff.id, player_buff_ids)
                    and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
                if job_util.can_use_job_ability(job_ability:get_job_ability_name()) and self:conditions_check(job_ability, buff, windower.ffxi.get_player()) then
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
                    if target and self:conditions_check(spell, buff, target) then
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
            if party_member:is_alive() then
                for spell in self.party_spells:it() do
                    local buff = buff_util.buff_for_spell(spell:get_spell().id)
                    if buff and spell:isEnabled() and not (party_member:has_buff(buff.id) or (party_member:is_trust() and self.buff_tracker:has_buff(party_member:get_mob().id, buff.id)))
                            and not (buff_util.conflicts_with_buffs(buff.id, party_member:get_buff_ids()))
                            and spell_util.can_cast_spell(spell:get_spell().id) then
                        local target = party_member:get_mob()
                        if target and self:conditions_check(spell, buff, target) then
                            if self:cast_spell(spell, target.index) then
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

function Buffer:cast_spell(spell, target_index)
    if spell_util.can_cast_spell(spell:get_spell().id) then
        if spell:get_consumable() and not player_util.has_item(spell:get_consumable()) then
            return false
        end
        local actions = L{ WaitAction.new(0, 0, 0, 1.5) }

        local can_cast_spell = true
        for job_ability_name in spell:get_job_abilities():it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if can_cast_spell and job_ability and not buff_util.is_buff_active(job_ability.status) then
                if job_ability.type == 'Scholar' then
                    actions:append(StrategemAction.new(job_ability_name))
                    actions:append(WaitAction.new(0, 0, 0, 1))
                else
                    if not job_util.can_use_job_ability(job_ability_name) then
                        can_cast_spell = false
                    else
                        actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                        actions:append(WaitAction.new(0, 0, 0, 1))
                    end
                end
            end
        end

        if can_cast_spell then
            self.last_buff_time = os.time()

            actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
            actions:append(WaitAction.new(0, 0, 0, 2))

            self.action_queue:push_action(SequenceAction.new(actions, 'buffer_'..spell:get_spell().en), true)
            return true
        else
            return false
        end
    else
        return false
    end
end

function Buffer:get_job_abilities()
    return self.job_abilities
end

function Buffer:get_self_spells()
    return self.self_spells
end

function Buffer:set_self_buffs(self_buffs)
    local spells = self_buffs:filter(function(b) return b.__type ~= JobAbility.__type end)
    self.self_spells = (spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
    self.self_spells_enabled = true

    local job_abilities = self_buffs:filter(function(b) return b.__type == JobAbility.__type end)
    self:set_job_abilities(job_abilities)
end

function Buffer:set_job_abilities(job_abilities)
    self.job_abilities = (job_abilities or L{}):filter(function(job_ability) return job_util.knows_job_ability(job_ability:get_job_ability_id()) == true  end)
    self.job_abilities_enabled = true
end

function Buffer:get_party_spells()
    return self.party_spells
end

function Buffer:set_party_buffs(party_buffs)
    self.party_spells = (party_buffs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
    self.party_spells_enabled = true
end

function Buffer:is_self_buff_active(spell)
    local player_buff_ids = L(windower.ffxi.get_player().buffs)

    local buff = buff_util.buff_for_spell(spell:get_spell().id)
    if buff and buff_util.is_buff_active(buff.id, player_buff_ids) or buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
        return true
    end
    return false
end

function Buffer:is_job_ability_buff_active(job_ability_name)
    local player_buff_ids = L(windower.ffxi.get_player().buffs)

    local job_ability = res.job_abilities:with('en', job_ability_name)
    if job_ability then
        local buff = buff_util.buff_for_job_ability(job_ability.id)
        if buff and buff_util.is_buff_active(buff.id, player_buff_ids) or buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
            return true
        end
    end
    return false
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:get_type()
    return "buffer"
end

function Buffer:tostring()
    local result = ""

    result = "Job Abilities:\n"
    if self.job_abilities:length() > 0 then
        for job_ability in self.job_abilities:it() do
            result = result..'• '..job_ability:get_job_ability_name()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    result = result.."\nSelf Buffs:\n"
    if self.self_spells:length() > 0 then
        for spell in self.self_spells:it() do
            result = result..'• '..spell:description()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    result = result.."\nParty Buffs:\n"
    if self.party_spells:length() > 0 then
        for spell in self.party_spells:it() do
            result = result..'• '..spell:description()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    return result
end

return Buffer