require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local ScholarTrust = setmetatable({}, {__index = Trust })
ScholarTrust.__index = ScholarTrust

local Scholar = require('cylibs/entity/jobs/SCH')

local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Healer = require('cylibs/trust/roles/healer')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')
local Skillchainer = require('cylibs/trust/roles/skillchainer')
local StatusRemover = require('cylibs/trust/roles/status_remover')

state.AutoArtsMode = M{['description'] = 'Auto Arts Mode', 'Off', 'LightArts', 'DarkArts'}

function ScholarTrust.new(settings, action_queue, battle_settings, trust_settings)
    local self = setmetatable(Trust.new(action_queue, S{}, trust_settings, Scholar.new(trust_settings)), ScholarTrust)

    self.settings = settings
    self.battle_settings = battle_settings
    self.action_queue = action_queue
    self.current_arts_mode = 'Off'
    self.arts_roles = S{}

    if state.AutoArtsMode.value ~= 'Off' then
        self:switch_arts(state.AutoArtsMode.value)
    end

    return self
end

function ScholarTrust:destroy()
    Role.destroy(self)

    if self.auto_arts_mode_id then
        state.AutoArtsMode:on_state_change():removeAction(self.auto_arts_mode_id)
    end
end

function ScholarTrust:on_init()
    Trust.on_init(self)

    self.auto_arts_mode_id = state.AutoArtsMode:on_state_change():addAction(function(_, new_value)
        self:switch_arts(new_value)
    end)

    self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
        self:get_job():set_trust_settings(new_trust_settings)
        self:update_for_arts(self.current_arts_mode)
    end)
end

function ScholarTrust:job_target_change(target_index)
    Trust.job_target_change(self, target_index)

    self.target_index = target_index
end

function ScholarTrust:tic(old_time, new_time)
    Trust.tic(self, old_time, new_time)

    self:check_arts()
    self:check_sublimation()
    self:check_mp()
end

function ScholarTrust:check_arts()
    self:switch_arts(state.AutoArtsMode.value)
end

function ScholarTrust:check_sublimation()
    if buff_util.is_buff_active(buff_util.buff_id('Refresh')) then
        return
    end
    if self:get_job():is_sublimation_active() then
        if windower.ffxi.get_player().vitals.mpp < 20 then
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Sublimation'), true)
        end
    elseif job_util.can_use_job_ability('Sublimation') then
        self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Sublimation'), true)
    end
end

function ScholarTrust:check_mp()
    if windower.ffxi.get_player().vitals.mpp < 40 then
        if self.target_index and windower.ffxi.get_player().vitals.tp > 1000 then
            self.action_queue:push_action(WeaponSkillAction.new('Myrkr'), true)
        end
    end
end

function ScholarTrust:switch_arts(new_arts_mode)
    if self.current_arts_mode == new_arts_mode then
        return
    end
    self.current_arts_mode = new_arts_mode

    self:update_for_arts(self.current_arts_mode)
end

function ScholarTrust:update_for_arts(new_arts_mode)
    for role in self.arts_roles:it() do
        self:remove_role(role)
    end
    self.arts_roles = S{}

    if new_arts_mode == 'LightArts' then
        self.arts_roles = S{
            Buffer.new(self.action_queue, S{'Light Arts'}, self:get_job():get_light_arts_self_buffs(), self:get_job():get_light_arts_party_buffs()),
            Debuffer.new(self.action_queue),
            Healer.new(self.action_queue, self:get_job()),
            StatusRemover.new(action_queue, job),
            Skillchainer.new(action_queue, L{'auto', 'prefer'}, self:get_trust_settings().Skillchains),
            --Puller.new(self.action_queue, self.battle_settings.targets, 'Dia II', nil)
        }
    elseif new_arts_mode == 'DarkArts' then
        self.arts_roles = S{
            Buffer.new(self.action_queue, S{'Dark Arts'}, self:get_job():get_dark_arts_self_buffs(), self:get_job():get_dark_arts_party_buffs()),
            Debuffer.new(self.action_queue),
            Dispeler.new(self.action_queue, L{ Spell.new('Dispel') }, L{'Addendum: Black'}),
            Nuker.new(self.action_queue),
            Skillchainer.new(action_queue, L{'auto', 'prefer'}, self:get_trust_settings().Skillchains),
            --Puller.new(self.action_queue, self.battle_settings.targets, 'Dia II', nil)
        }
    end

    for role in self.arts_roles:it() do
        self:add_role(role)
    end
end

return ScholarTrust