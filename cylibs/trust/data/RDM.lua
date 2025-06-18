---------------------------
-- Trust file for Red Mage. In addition to base trust functionality, a Red Mage trust
-- will buff, debuff, heal, dispel, pull and skillchain.
-- @class module
-- @name RedMageTrust

RedMage = require('cylibs/entity/jobs/RDM')

local Trust = require('cylibs/trust/trust')
local RedMageTrust = setmetatable({}, {__index = Trust })
RedMageTrust.__index = RedMageTrust

local Barspeller = require('cylibs/trust/roles/barspeller')
local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Healer = require('cylibs/trust/roles/healer_v2')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

state.AutoConvertMode = M{['description'] = 'Auto Convert Mode', 'Off', 'Auto'}
state.AutoConvertMode:set_description('Auto', "Use Convert when MP is low.")

-------
-- Default initializer for a Red Mage trust.
-- @tparam T settings Settings
-- @tparam ActionQueue action_queue Action queue
-- @tparam T battle_settings Battle settings
-- @treturn RedMageTrust Red Mage trust
function RedMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = RedMage.new(trust_settings.CureSettings)
	local roles = S{
		Healer.new(action_queue, trust_settings.CureSettings, job),
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Barspeller.new(action_queue, job),
		Debuffer.new(action_queue, trust_settings.DebuffSettings, job),
		Dispeler.new(action_queue, L{ Spell.new('Dispel') }, L{}, true),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
		StatusRemover.new(action_queue, trust_settings.StatusRemovalSettings, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), RedMageTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_mp_check = os.time()

	return self
end

function RedMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function RedMageTrust:on_deinit()
end

function RedMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
end

function RedMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return RedMageTrust