local Tank = setmetatable({}, {__index = Role })
Tank.__index = Tank

state.AutoTankMode = M{['description'] = 'Auto Tank Mode', 'Off', 'Auto'}
state.AutoTankMode:set_description('Auto', "Okay, I'll tank for the party.")

function Tank.new(action_queue, job_ability_names, spells)
    local self = setmetatable(Role.new(settings, action_queue), Tank)

    self.action_queue = action_queue
    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name) job_util.knows_job_ability(job_util.job_ability_id(job_ability_name))  end)
    self.spells = (spells or L{}):filter(function(spell) return spell_util.knows_spell(spell:get_spell().id) end)
    self.enmity_last_checked = os.time()

    return self
end

function Tank:destroy()
    Role.destroy(self)
end

function Tank:on_add()
    Role.on_add(self)
end

function Tank:target_change(target_index)
    Role.target_change(self, target_index)
end

function Tank:tic(_, _)
    if self.target_index == nil then return end

    self:check_enmity()
end

function Tank:check_enmity()
    local target = windower.ffxi.get_mob_by_index(self.target_index)

    if state.AutoTankMode.value == 'Off' or os.time() - self.enmity_last_checked < 5 or not party_util.party_claimed(target.id) then
        return
    end
    self.enmity_last_checked = os.time()

    for enmity_spell in self.spells:it() do
        if spell_util.can_cast_spell(enmity_spell:get_spell().id) then
            local spell_action = SequenceAction.new(L{
                SpellAction.new(0, 0, 0, enmity_spell:get_spell().id, self.target_index, self:get_player()),
                WaitAction.new(0, 0, 0, 2),
                SpellAction.new(0, 0, 0, spell_util.spell_id('Foil'), nil, self:get_player()),
            }, 'tank_enmity')
            spell_action.priority = ActionPriority.high

            self.action_queue:push_action(spell_action, true)
            return
        end
    end
end

function Tank:allows_duplicates()
    return true
end

function Tank:get_type()
    return "tank"
end

return Tank