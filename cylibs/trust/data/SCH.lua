local Trust = require('cylibs/trust/trust')
local ScholarTrust = setmetatable({}, {__index = Trust })
ScholarTrust.__index = ScholarTrust

local Scholar = require('cylibs/entity/jobs/SCH')

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local DisposeBag = require('cylibs/events/dispose_bag')
local Healer = require('cylibs/trust/roles/healer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

state.AutoArtsMode = M{['description'] = 'Auto Arts Mode', 'Off', 'LightArts', 'DarkArts'}

function ScholarTrust.new(settings, action_queue, battle_settings, trust_settings)
    local job = Scholar.new(trust_settings)

    local self = setmetatable(Trust.new(action_queue, S{
        Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
        Debuffer.new(action_queue, trust_settings.DebuffSettings, job),
        Healer.new(action_queue, job),
        ManaRestorer.new(action_queue, L{'Myrkr', 'Spirit Taker'}, L{}, 40),
        Puller.new(action_queue, trust_settings.PullSettings),
        StatusRemover.new(action_queue, job),
        Dispeler.new(action_queue, L{ Spell.new('Dispel', L{'Addendum: Black'}) }, L{}, true),
        MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Ebullience' }, job, false),
        Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
    }, trust_settings, job), ScholarTrust)

    self.settings = settings
    self.battle_settings = battle_settings
    self.action_queue = action_queue
    self.current_arts_mode = 'Off'
    self.dispose_bag = DisposeBag.new()

    return self
end

function ScholarTrust:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function ScholarTrust:on_init()
    Trust.on_init(self)

    self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
        self:get_job():set_trust_settings(new_trust_settings)

        local debuffer = self:role_with_type("debuffer")
        debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

        local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
        for role in nuker_roles:it() do
            role:set_nuke_settings(new_trust_settings.NukeSettings)
        end
    end)

    if self:get_job():is_light_arts_active() then
        self:switch_arts('LightArts')
    elseif self:get_job():is_dark_arts_active() then
        self:switch_arts('DarkArts')
    end

    self.dispose_bag:add(self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
        local buff_name = buff_util.buff_name(buff_id)
        if L{'Light Arts', 'Addendum: White'}:contains(buff_name) then
            self:switch_arts('LightArts')
        elseif L{'Dark Arts', 'Addendum: Black'}:contains(buff_name) then
            self:switch_arts('DarkArts')
        end
    end, self:get_party():get_player():on_gain_buff()))
end

function ScholarTrust:tic(old_time, new_time)
    Trust.tic(self, old_time, new_time)

    self:check_gambits(self.gambits)
end

function ScholarTrust:switch_arts(new_arts_mode)
    if self.current_arts_mode == new_arts_mode then
        return
    end
    logger.notice("Switching to", new_arts_mode, "from", self.current_arts_mode, "AutoArtsMode: ", state.AutoArtsMode.value)

    self.current_arts_mode = new_arts_mode

    self:update_for_arts(self.current_arts_mode)
end

function ScholarTrust:update_for_arts(new_arts_mode)
end

return ScholarTrust