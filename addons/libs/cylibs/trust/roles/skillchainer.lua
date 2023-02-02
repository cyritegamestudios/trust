local Skillchainer = setmetatable({}, {__index = Role })
Skillchainer.__index = Skillchainer

local SkillchainMaker = require('cylibs/battle/skillchains/skillchain_maker')

state.AutoAftermathMode = M{['description'] = 'Auto Aftermath Mode', 'Off', 'Auto'}
state.AutoAftermathMode:set_description('Auto', "Okay, I'll try to keep aftermath on.")

state.AutoSkillchainMode = M{['description'] = 'Auto Skillchain Mode', 'Off', 'Auto', 'Cleave', 'Spam'}
state.AutoSkillchainMode:set_description('Auto', "Okay, I'll try to make skillchains.")
state.AutoSkillchainMode:set_description('Cleave', "Okay, I'll try to cleave monsters.")
state.AutoSkillchainMode:set_description('Spam', "Okay, I'll use the same weapon skill as soon as I get TP.")

state.SkillchainDelayMode = M{['description'] = 'Skillchain Delay Mode', 'Off', 'Maximum'}
state.SkillchainDelayMode:set_description('Maximum', "Okay, I'll wait until the end of the skillchain window to use my next weapon skill.")

state.SkillchainPartnerMode = M{['description'] = 'Skillchain Partner Mode', 'Off', 'Auto', 'Open', 'Close'}
state.SkillchainPartnerMode:set_description('Auto', "Okay, I'll let party members with the highest TP go first.")
state.SkillchainPartnerMode:set_description('Open', "Okay, I'll only open skillchains.")
state.SkillchainPartnerMode:set_description('Close', "Okay, I'll only close skillchains.")

state.SkillchainPriorityMode = M{['description'] = 'Skillchain Priority Mode', 'Off', 'Prefer', 'Strict'}
state.SkillchainPartnerMode:set_description('Prefer', "Okay, I'll prioritize using certain weapon skills.")
state.SkillchainPartnerMode:set_description('Strict', "Okay, I'll only use certain weapon skills.")

function Skillchainer.new(action_queue, skillchain_params, skillchain_settings)
    local self = setmetatable(Role.new(action_queue), Skillchainer)

    self.action_queue = action_queue
    self.skillchain_params = skillchain_params
    self.skillchain_settings = skillchain_settings

    return self
end

function Skillchainer:destroy()
    Role.destroy(self)

    if self.skillchain_maker then
        self.skillchain_maker:destroy()
    end
end

function Skillchainer:on_add()
    Role.on_add(self)

    self.skillchain_maker = SkillchainMaker.new(self.skillchain_settings, state.AutoSkillchainMode, state.SkillchainPriorityMode, state.SkillchainPartnerMode, state.AutoAftermathMode)
    self.skillchain_maker:start_monitoring()
    self.skillchain_maker:on_perform_next_weapon_skill():addAction(function(_, weapon_skill_name)
        self:job_weapon_skill(weapon_skill_name)
    end)
end

function Skillchainer:job_weapon_skill(weapon_skill_name)
    if state.AutoSkillchainMode.value == 'Off' then return end

    local ws = res.weapon_skills:with('en', weapon_skill_name)
    if ws then
        local ws_action = SequenceAction.new(L{
            WeaponSkillAction.new(ws.name),
            WaitAction.new(0, 0, 0, 2)
        }, 'sc_'..ws.en)
        ws_action.priority = ActionPriority.highest

        self.action_queue:push_action(ws_action, true)
    end
end

function Skillchainer:allows_duplicates()
    return false
end

function Skillchainer:get_type()
    return "skillchainer"
end

return Skillchainer