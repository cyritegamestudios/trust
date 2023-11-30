local job_util = require('cylibs/util/job_util')
local WeaponSkillAction = require('cylibs/actions/weapon_skill')

local ManaRestorer = setmetatable({}, {__index = Role })
ManaRestorer.__index = ManaRestorer

state.AutoRestoreManaMode = M{['description'] = 'Auto Restore Mana Mode', 'Auto', 'Off'}
state.AutoRestoreManaMode:set_description('Auto', "Okay, I'll try to recover MP when I'm low.")

function ManaRestorer.new(action_queue, weapon_skill_names, mpp_threshold)
    local self = setmetatable(Role.new(action_queue), ManaRestorer)

    local weapon_skill_names = weapon_skill_names:filter(function(weapon_skill_name) return job_util.knows_weapon_skill(weapon_skill_name)  end)
    if weapon_skill_names:length() > 0 then
        self.weapon_skill_name = weapon_skill_names[1]
    end
    self.mpp_threshold = mpp_threshold
    self.last_vitals_check_time = os.time()

    return self
end

function ManaRestorer:destroy()
    Role.destroy(self)
end

function ManaRestorer:on_add()
    Role.on_add(self)
end

function ManaRestorer:target_change(target_index)
    Role.target_change(self, target_index)
end

function ManaRestorer:tic(new_time, old_time)
    if state.AutoRestoreManaMode.value == 'Off' or self.target_index == nil or windower.ffxi.get_player().vitals.mpp > self.mpp_threshold then
        return
    end

    self:check_weapon_skill()
end

function ManaRestorer:check_weapon_skill()
    if self.weapon_skill_name == nil then
        return
    end
    if windower.ffxi.get_player().vitals.tp >= 1000 then
        self.action_queue:push_action(WeaponSkillAction.new(self.weapon_skill_name), true)
    end
end

function ManaRestorer:allows_duplicates()
    return false
end

function ManaRestorer:get_type()
    return "manarestorer"
end

return ManaRestorer