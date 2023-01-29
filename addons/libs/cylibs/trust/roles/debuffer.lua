local Debuffer = setmetatable({}, {__index = Role })
Debuffer.__index = Debuffer

state.AutoDebuffMode = M{['description'] = 'Auto Debuff Mode', 'Off', 'Auto'}
state.AutoDebuffMode:set_description('Auto', "Okay, I'll debuff the monster.")

state.AutoSilenceMode = M{['description'] = 'Auto Silence Mode', 'Off', 'Auto'}
state.AutoSilenceMode:set_description('Auto', "Okay, I'll try to silence monsters that cast spells.")

function Debuffer.new(action_queue, debuff_spells)
    local self = setmetatable(Role.new(action_queue), Debuffer)

    self:set_debuff_spells(debuff_spells)
    self.last_debuff_time = os.time()

    return self
end

function Debuffer:destroy()
    Role.destroy(self)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end
end

function Debuffer:target_change(target_index)
    Role.target_change(self, target_index)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end

    if target_index then
        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()
        self.battle_target:on_spell_finish():addAction(
                function (m, target_index, spell_id)
                    if self.target_index then
                        local spell = res.spells:with('id', spell_id)
                        if spell then
                            if state.AutoSilenceMode.value ~= 'Off' then
                                self:cast_spell(Spell.new('Silence'), self.target_index)
                            end
                        end
                    end
                end)
    end
end

function Debuffer:tic(new_time, old_time)
    if state.AutoDebuffMode.value == 'Off' or (os.time() - self.last_debuff_time) < 8 then
        return
    end

    self:check_debuffs()
end

function Debuffer:check_debuffs()
    if self.battle_target == nil or not party_util.party_claimed(self.battle_target:get_mob().id) then return end

    for spell in self.debuff_spells:it() do
        local debuff = buff_util.debuff_for_spell(spell:get_spell().id)
        if debuff and not self.battle_target:has_debuff(debuff.id) then
            self:cast_spell(spell, self.battle_target:get_mob().index)
            return
        end
    end
end

function Debuffer:cast_spell(spell, target_index)
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
            self.last_debuff_time = os.time()

            actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
            actions:append(WaitAction.new(0, 0, 0, 2))

            local debuff_action = SequenceAction.new(actions, 'debuffer_'..spell:get_spell().en)
            debuff_action.priority = ActionPriority.low

            self.action_queue:push_action(debuff_action, true)

            return
        end
    end
end

function Debuffer:set_debuff_spells(debuff_spells)
    self.debuff_spells = (debuff_spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
end

function Debuffer:allows_duplicates()
    return true
end

function Debuffer:get_type()
    return "debuffer"
end

return Debuffer