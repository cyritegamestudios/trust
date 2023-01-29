require('tables')
require('lists')
require('logger')

Bard = require('cylibs/entity/jobs/BRD')

local Trust = require('cylibs/trust/trust')
local BardTrust = setmetatable({}, {__index = Trust })
BardTrust.__index = BardTrust

local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Puller = require('cylibs/trust/roles/puller')
local Singer = require('cylibs/trust/roles/singer')

state.AutoSongMode = M{['description'] = 'Auto Song Mode', 'Off', 'Auto', 'Dummy'}
state.AutoSleepMode = M{['description'] = 'Auto Sleep Mode', 'Off', 'Auto'}

function BardTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Bard.new(trust_settings)
	local roles = S{
		Debuffer.new(action_queue, trust_settings.Debuffs),
		Singer.new(action_queue, trust_settings.DummySongs, trust_settings.Songs, trust_settings.PartyBuffs, job, state.AutoSongMode, ActionPriority.medium),
		Dispeler.new(action_queue, L{ Spell.new('Magic Finale') }),
		Puller.new(action_queue, battle_settings.targets, 'Carnage Elegy', nil)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), BardTrust)

	self.settings = settings
	self.num_songs = trust_settings.NumSongs
	self.action_queue = action_queue

	return self
end

function BardTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self.num_songs = new_trust_settings.NumSongs

		local singer = self:role_with_type("singer")

		singer:set_dummy_songs(new_trust_settings.DummySongs)
		singer:set_songs(new_trust_settings.Songs)
		singer:set_pianissimo_songs(new_trust_settings.PartyBuffs)

		local debuffer = self:role_with_type("debuffer")

		debuffer:set_debuff_spells(new_trust_settings.Debuffs)
	end)
end

function BardTrust:destroy()
	Trust.destroy(self)
end

function BardTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function BardTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

function BardTrust:check_lullaby()
	if state.AutoSleepMode.value == 'Off' then
		return
	end

	local nearby_mobs = windower.ffxi.get_mob_array()
	for _, p in pairs(nearby_mobs) do
		if p.is_npc and p.distance:sqrt() < 10 and p.claim_id ~= nil and p.status ~= 3 then
			local target = windower.ffxi.get_mob_by_id(p.claim_id)
			if target ~= nil and L{"Hydranger","Myunmyunmyun"}:contains(target.name) then
				return true
			end
		end
	end
	return false
end

return BardTrust



