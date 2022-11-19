local res = require('resources')

local Buffer = setmetatable({}, {__index = Role })
Buffer.__index = Buffer

function Buffer.new(action_queue, job_ability_names, self_spells, party_spells, state_var, buff_action_priority)
    local self = setmetatable(Role.new(action_queue), Buffer)

    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name) return job_util.knows_job_ability(job_util.job_ability_id(job_ability_name)) == true  end)
    self.job_abilities_enabled = true
    self.self_spells = (self_spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
    self.self_spells_enabled = true
    self.party_spells = (party_spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
    self.party_spells_enabled = true
    self.state_var = state_var or state.AutoBuffMode
    self.buff_action_priority = buff_action_priority or ActionPriority.default
    self.last_buff_time = os.time()

    return self
end

function Buffer:destroy()
    Role.destroy(self)
end

function Buffer:on_add()
    Role.on_add(self)

    if not self.job_ability_names:empty() then
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

function Buffer:tic(new_time, old_time)
    if self.state_var.value == 'Off'
            or (os.time() - self.last_buff_time) < 8 then
        return
    end
    self:check_buffs()
end

function Buffer:range_check(spell)
    if spell:is_aoe() then
        return #self:get_party():get_party_members(true, spell:get_spell().range) >= math.min(self:get_party():num_party_members(), spell:num_targets_required())
    else
        return true
    end
end

function Buffer:check_buffs()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)

    -- Job abilities
    if self.job_abilities_enabled then
        for job_ability_name in self.job_ability_names:it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if job_ability then
                local buff = buff_util.buff_for_job_ability(job_ability.id)
                if buff and not buff_util.is_buff_active(buff.id, player_buff_ids)
                        and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
                    if job_util.can_use_job_ability(job_ability_name) then
                        self.last_buff_time = os.time()
                        self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability.en), true)
                        return
                    end
                end
            end
        end
    end

    if self:get_player():is_moving() then
        return
    end

    -- Spells (self buffs)
    if self.self_spells_enabled then
        for spell in self.self_spells:it() do
            local buff = buff_util.buff_for_spell(spell:get_spell().id)
            if buff and not buff_util.is_buff_active(buff.id, player_buff_ids) and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids)
                    and self:range_check(spell) then
                self:cast_spell(spell, windower.ffxi.get_player().index)
                return
            end
        end
    end

    -- Spells (party buffs)
    if self.party_spells_enabled then
        for party_member in self:get_party():get_party_members(false, 21):it() do
            if party_member:is_alive() then
                for spell in self.party_spells:it() do
                    local buff = buff_util.buff_for_spell(spell:get_spell().id)
                    if buff and not party_member:has_buff(buff.id) and spell:get_job_names():contains(party_member:get_main_job_short()) then
                        self:cast_spell(spell, party_member:get_mob().index)
                        return
                    end
                end
            end
        end
    end
end

function Buffer:cast_spell(spell, target_index)
    if spell_util.can_cast_spell(spell:get_spell().id) then
        if spell:get_consumable() and not player_util.has_item(spell:get_consumable()) then
            return
        end

        local actions = L{}

        local can_cast_spell = true
        for job_ability_name in spell:get_job_abilities():it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if job_ability and not buff_util.is_buff_active(job_ability.status) then
                if job_ability.type == 'Scholar' then
                    if player_util.get_current_strategem_count() >= spell:get_job_abilities():length() then
                        actions:append(StrategemAction.new(job_ability_name))
                        actions:append(WaitAction.new(0, 0, 0, 1))
                    else
                        can_cast_spell = false
                    end
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

            return
        end
    end
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:get_type()
    return "buffer"
end

return Buffer