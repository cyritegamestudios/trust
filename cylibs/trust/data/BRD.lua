require('tables')
require('lists')
require('logger')

Bard = require('cylibs/entity/jobs/BRD')

local Trust = require('cylibs/trust/trust')
local BardTrust = setmetatable({}, {__index = Trust })
BardTrust.__index = BardTrust

local BardModes = require('cylibs/trust/data/modes/BRD')
local BardTrustCommands = require('cylibs/trust/commands/BRD') -- keep this for dependency script
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local ModeDelta = require('cylibs/modes/mode_delta')
local Puller = require('cylibs/trust/roles/puller')
local Singer = require('cylibs/trust/roles/singer')
local Sleeper = require('cylibs/trust/roles/sleeper')

state.AutoSongMode = M{['description'] = 'Sing Songs', 'Off', 'Auto', 'Dummy'}
state.AutoSongMode:set_description('Auto', "Okay, I'll keep songs on the party.")
state.AutoSongMode:set_description('Dummy', "Okay, I'll only sing dummy songs.")

state.AutoPianissimoMode = M{['description'] = 'Pianissimo Type', 'Merged', 'Override'}
state.AutoPianissimoMode:set_description('Merged', "Okay, I'll make sure to keep all songs on everyone.")
state.AutoPianissimoMode:set_description('Override', "Okay, I'll only focus on Pianissimo songs.")

state.AutoNitroMode = M{['description'] = 'Use Nitro', 'Auto', 'Off'}
state.AutoNitroMode:set_description('Auto', "Okay, I'll use Nightingale and Troubadour before singing songs.")

state.AutoClarionCallMode = M{['description'] = 'Use Clarion Call', 'Off', 'Auto'}
state.AutoClarionCallMode:set_description('Auto', "Okay, I'll use Clarion Call before Nightingale and Troubadour.")

function BardTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Bard.new(trust_settings)
	local roles = S{
		Debuffer.new(action_queue, trust_settings.Debuffs),
		Singer.new(action_queue, trust_settings.SongSettings.DummySongs, trust_settings.SongSettings.Songs, trust_settings.SongSettings.PianissimoSongs, job, state.AutoSongMode, ActionPriority.medium),
		Dispeler.new(action_queue, L{ Spell.new('Magic Finale') }, L{}, true),
		Puller.new(action_queue, battle_settings.targets, L{ Spell.new('Carnage Elegy') }),
		Sleeper.new(action_queue, L{ Spell.new('Horde Lullaby'), Spell.new('Horde Lullaby II') }, 2)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), BardTrust)

	self.settings = settings
	self.num_songs = trust_settings.NumSongs
	self.action_queue = action_queue
	self.song_modes_delta = ModeDelta.new(BardModes.Singing)

	return self
end

function BardTrust:on_init()
	Trust.on_init(self)

	local singer = self:role_with_type("singer")
	if singer then
		singer:on_songs_begin():addAction(function()
			self:get_party():add_to_chat(self.party:get_player(), "Singing songs, hold tight.", "on_songs_begin", 5)
			self.song_modes_delta:apply(true)
		end)
		singer:on_songs_end():addAction(function()
			self:get_party():add_to_chat(self.party:get_player(), "Alright, you're good to go!", "on_songs_end", 5)
			self.song_modes_delta:remove(true)
		end)
	end

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self.num_songs = new_trust_settings.NumSongs

		local singer = self:role_with_type("singer")

		singer:set_dummy_songs(new_trust_settings.SongSettings.DummySongs)
		singer:set_songs(new_trust_settings.SongSettings.Songs)
		singer:set_pianissimo_songs(new_trust_settings.SongSettings.PianissimoSongs)

		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_spells(new_trust_settings.Debuffs)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
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

return BardTrust



