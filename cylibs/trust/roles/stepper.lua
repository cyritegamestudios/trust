local DisposeBag = require('cylibs/events/dispose_bag')
local StepTracker = require('cylibs/battle/trackers/step_tracker')
local buff_util = require('cylibs/util/buff_util')
local spell_util = require('cylibs/util/spell_util')

local Stepper = setmetatable({}, {__index = Role })
Stepper.__index = Stepper
Stepper.__class = "Stepper"

state.AutoStepMode = M{['description'] = 'Auto Step Mode', 'Off', 'Auto'}
state.AutoStepMode:set_description('Auto', "Okay, I'll debuff the monster with steps.")


function Stepper.new(action_queue, steps)
    local self = setmetatable(Role.new(action_queue), Stepper)

    self:set_steps(steps)

    self.dispose_bag = DisposeBag.new()
    self.last_step_time = os.time()

    return self
end

function Stepper:destroy()
    Role.destroy(self)

    self.battle_target_destroyables:destroy()
end

function Stepper:on_add()
    Role.on_add(self)
end

function Stepper:target_change(target_index)
    Role.target_change(self, target_index)

    self.battle_target_destroyables:destroy()

    if target_index then
        self.last_step_time = os.time()

        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()

        self.battle_target_destroyables:addAny(L{ self.battle_target })
    end
end

function Stepper:tic(new_time, old_time)
    if not self:get_player():is_engaged() or self.battle_target == nil or not self.battle_target:is_valid()
            or not party_util.party_claimed(self.battle_target:get_mob().id) then
        return
    end

    self:check_steps()
end

function Stepper:check_steps()
    if state.AutoStepMode.value == 'Off' or (os.time() - self.last_step_time) < 8 then
        return
    end

    --[[local player_buff_ids = L(windower.ffxi.get_player().buffs)

    for step in self.steps:it() do
        local buff = buff_util.buff_for_job_ability(job_ability:get_job_ability_id())
        if buff and not buff_util.is_buff_active(buff.id, player_buff_ids)
                and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids) then
            if job_util.can_use_job_ability(job_ability:get_job_ability_name()) and self:conditions_check(job_ability, windower.ffxi.get_player()) then
                self.last_buff_time = os.time()
                self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability:get_job_ability_name()), true)
                return
            end
        end
    end]]
end

function Stepper:set_steps(steps)
    self.steps = (steps or L{}):filter(function(step) return job_util.knows_job_ability(step:get_job_ability_id()) == true  end)
end

function Stepper:allows_duplicates()
    return false
end

function Stepper:get_type()
    return "stepper"
end

function Stepper:tostring()
    local result = ""

    result = result.."Steps:\n"
    if self.steps:length() > 0 then
        for step in self.steps:it() do
            result = result..'• '..step:description()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    return result
end

return Stepper