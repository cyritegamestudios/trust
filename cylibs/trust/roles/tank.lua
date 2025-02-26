local JobAbilityAction = require('cylibs/actions/job_ability')
local job_util = require('cylibs/util/job_util')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')
local spell_util = require('cylibs/util/spell_util')
local WaitAction = require('cylibs/actions/wait')

local Tank = setmetatable({}, {__index = Role })
Tank.__index = Tank

state.AutoTankMode = M{['description'] = 'Auto Tank Mode', 'Off', 'Auto'}
state.AutoTankMode:set_description('Auto', "Okay, I'll tank for the party.")

function Tank.new(action_queue, job_ability_names, spells)
    local self = setmetatable(Role.new(action_queue), Tank)
    self.action_queue = action_queue
    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name) return job_util.knows_job_ability(job_util.job_ability_id(job_ability_name))  end)
    self.spells = (spells or L{}):filter(function(spell) return spell_util.knows_spell(spell:get_spell().id) end)
    self.enmity_action_delay = 10
    self.enmity_last_checked = os.time() - self.enmity_action_delay

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
    local target = self:get_target()

    if state.AutoTankMode.value == 'Off' or os.time() - self.enmity_last_checked < self.enmity_action_delay or target == nil or target:get_mob() == nil
            or not party_util.party_claimed(target:get_id()) then
        return
    end

    for enmity_spell in self.spells:it() do
        if spell_util.can_cast_spell(enmity_spell:get_spell().id) then
            self.enmity_last_checked = os.time()
            print('tank stuff')
            local actions = L{
                SpellAction.new(0, 0, 0, enmity_spell:get_spell().id, target:get_mob().index, self:get_player()),
            }

            if spell_util.can_cast_spell(spell_util.spell_id('Foil')) then
                actions:append(WaitAction.new(0, 0, 0, 2))
                actions:append(SpellAction.new(0, 0, 0, spell_util.spell_id('Foil'), nil, self:get_player()))

            end

            local spell_action = SequenceAction.new(actions, 'tank_enmity')
            spell_action.priority = ActionPriority.high

            self.action_queue:push_action(spell_action, true)
            return
        end
    end

    for enmity_job_ability in self.job_ability_names:it() do
        if job_util.can_use_job_ability(enmity_job_ability) then
            self.enmity_last_checked = os.time()

            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, enmity_job_ability, self.target_index), true)
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