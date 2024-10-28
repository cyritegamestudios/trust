Ninja = require('cylibs/entity/jobs/NIN')

local Trust = require('cylibs/trust/trust')
local NinjaTrust = setmetatable({}, {__index = Trust })
NinjaTrust.__index = NinjaTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')


function NinjaTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Ninja.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs or L{}),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Futae' }, job),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings.Targets, trust_settings.PullSettings.Abilities),

	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), NinjaTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_utsusemi_spell_id = nil
	self.last_utsusemi_cancel_time = os.time()

	return self
end

function NinjaTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		buffer:set_job_abilities(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)

		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_spells(new_trust_settings.Debuffs)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)

	self:get_player():on_spell_begin():addAction(function(p, spell_id)
		if S{ 338, 339, 340 }:contains(spell_id) then
			if not self:get_job():should_cancel_shadows(self.last_utsusemi_spell_id, spell_id) then
				return
			end
			for copy_image_buff_id in L{ 66, 444, 445, 446 }:it() do
				if buff_util.is_buff_active(copy_image_buff_id) then
					if os.time() - self.last_utsusemi_cancel_time < 1 then
						return
					end
					self.last_utsusemi_cancel_time = os.time()
					windower.ffxi.cancel_buff(copy_image_buff_id)
					self.last_utsusemi_spell_id = nil
					break
				end
			end
		end
	end)

	self:get_player():on_spell_finish():addAction(function(p, spell_id, _)
		self.last_utsusemi_spell_id = spell_id
	end)
end

function NinjaTrust:destroy()
	Trust.destroy(self)
end

function NinjaTrust:get_last_utsusemi_spell_id()
	if not self:get_job():has_shadows() then
		self.last_utsusemi_spell_id = nil
	end
	return self.last_utsusemi_spell_id
end

return NinjaTrust



