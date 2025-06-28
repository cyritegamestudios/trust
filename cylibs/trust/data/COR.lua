Corsair = require('cylibs/entity/jobs/COR')

local Trust = require('cylibs/trust/trust')
local CorsairTrust = setmetatable({}, {__index = Trust })
CorsairTrust.__index = CorsairTrust

local Dispeler = require('cylibs/trust/roles/dispeler')
local DisposeBag = require('cylibs/events/dispose_bag')
local Frame = require('cylibs/ui/views/frame')
local Puller = require('cylibs/trust/roles/puller')
local Roller = require('cylibs/trust/roles/roller')
local Shooter = require('cylibs/trust/roles/shooter')

function CorsairTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Corsair.new(action_queue, state.AutoRollMode)
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Dark Shot') }, true),
		Shooter.new(action_queue, trust_settings.Shooter),
		Roller.new(action_queue, trust_settings.RollSettings, job),
		Puller.new(action_queue, trust_settings.PullSettings, job)
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), CorsairTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.dispose_bag = DisposeBag.new()

	return self
end

function CorsairTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local shooter = self:role_with_type("shooter")
		if shooter then
			shooter:set_shooter_settings(new_trust_settings.Shooter)
		end
	end)
end

function CorsairTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()
end

function CorsairTrust:get_widget()
	local CorsairWidget = require('ui/widgets/CorsairWidget')
	local corsairWidget = CorsairWidget.new(
			Frame.new(40, 285, 125, 57),
			self,
			windower.trust.ui.get_hud(),
			windower.trust.settings.get_job_settings('COR'),
			state.MainTrustSettingsMode,
			windower.trust.settings.get_mode_settings()
	)
	return corsairWidget, 'job'
end

return CorsairTrust



