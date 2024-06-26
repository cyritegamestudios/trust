Ninja = require('cylibs/entity/jobs/NIN')

local Trust = require('cylibs/trust/trust')
local NinjaTrust = setmetatable({}, {__index = Trust })
NinjaTrust.__index = NinjaTrust

local Buffer = require('cylibs/trust/roles/buffer')

function NinjaTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Ninja.new()), NinjaTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_utsusemi_spell_id = nil

	return self
end

function NinjaTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		buffer:set_job_abilities(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)

	self:get_player():on_spell_begin():addAction(function(p, spell_id)
		if S{ 338, 339, 340 }:contains(spell_id) then
			for copy_image_buff_id in L{ 66, 444, 445, 446 }:it() do
				if buff_util.is_buff_active(copy_image_buff_id) then
					windower.ffxi.cancel_buff(copy_image_buff_id)
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



