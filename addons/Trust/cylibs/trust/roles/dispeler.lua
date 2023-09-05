local spell_util = require('cylibs/util/spell_util')
local job_util = require('cylibs/util/job_util')
local Monster = require('cylibs/battle/monster')

local Dispeler = setmetatable({}, {__index = Role })
Dispeler.__index = Dispeler

state.AutoDispelMode = M{['description'] = 'Auto Dispel Mode', 'Auto', 'Off'}
state.AutoDispelMode:set_description('Auto', "Okay, I'll try to dispel monster buffs.")

function Dispeler.new(action_queue, spells, job_ability_names)
    local self = setmetatable(Role.new(action_queue), Dispeler)
    self.spells = (spells or L{}):filter(function(spell)
        if spell ~= nil then
            if spell:get_job_abilities() and spell:get_job_abilities():contains('Addendum: Black') then
                return true
            end
            return spell_util.knows_spell(spell:get_spell().id)
        end
        return false
    end)
    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name)
        if string.find(job_ability_name, 'Maneuver') then
            return true
        end
        return job_util.knows_job_ability(job_util.job_ability_id(job_ability_name)) == true
    end)
    return self
end

function Dispeler:destroy()
    Role.destroy(self)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end
end

function Dispeler:on_add()
    Role.on_add(self)
end

function Dispeler:target_change(target_index)
    Role.target_change(self, target_index)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end

    if target_index then
        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()
        self.battle_target:on_gain_buff():addAction(
                function (_, target_index, _)
                    self:dispel(target_index)
                end)
    end
end

function Dispeler:dispel(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)

    if state.AutoDispelMode.value == 'Off' or not party_util.party_claimed(target.id) then
        return
    end

    -- Spells
    for spell in self.spells:it() do
        if spell_util.can_cast_spell(spell:get_spell().id) then
            self:cast_spell(spell, target_index)
        end
        return
    end

    -- Job abilities
    for job_ability_name in self.job_ability_names:it() do
        if string.find(job_ability_name, 'Maneuver') then
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability_name), true)
        else
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability_name, target_index), true)
        end
        return
    end
end

function Dispeler:cast_spell(spell, target_index)
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

        local dispel_action = SequenceAction.new(actions, 'dispeler'..spell:get_spell().en)
        dispel_action.priority = ActionPriority.high

        self.action_queue:push_action(dispel_action, true)

        return
    end
end

function Dispeler:get_type()
    return "dispeler"
end

return Dispeler