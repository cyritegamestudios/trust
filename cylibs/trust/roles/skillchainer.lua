local Skillchainer = setmetatable({}, {__index = Role })
Skillchainer.__index = Skillchainer

state.AutoSkillchainMode = M{['description'] = 'Auto Skillchain Mode', 'Off', 'Auto'}

function Skillchainer.new(action_queue, skillchain_params)
    local self = setmetatable(Role.new(action_queue), Skillchainer)

    self.action_queue = action_queue
    self.skillchain_params = skillchain_params

    return self
end

function Skillchainer:destroy()
    Role.destroy(self)
end

function Skillchainer:on_add()
    Role.on_add(self)

    windower.send_command('input // lua r skillchains')

    coroutine.schedule(function()
        for param in self.skillchain_params:it() do
            windower.send_command('input // sc %s':format(param))
        end
    end, 1)
end

function Skillchainer:job_weapon_skill(weapon_skill_name)
    if state.AutoSkillchainMode.value == 'Off' then return end

    local ws = res.weapon_skills:with('en', weapon_skill_name)
    if ws then
        self.action_queue:push_action(SequenceAction.new(L{
            WeaponSkillAction.new(ws.name),
            WaitAction.new(0, 0, 0, 2)
        }, 'sc_'..ws.en), true)
    end
end

function Skillchainer:allows_duplicates()
    return false
end

function Skillchainer:get_type()
    return "skillchainer"
end

return Skillchainer