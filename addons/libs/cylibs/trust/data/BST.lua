require('tables')
require('lists')
require('logger')

Beastmaster = require('cylibs/entity/jobs/BST')

local Trust = require('cylibs/trust/trust')
local BeastmasterTrust = setmetatable({}, {__index = Trust })
BeastmasterTrust.__index = BeastmasterTrust

local Familiar = require('cylibs/entity/familiar')
local ReadyMoveAction = require('cylibs/actions/ready_move_action')

local Buffer = require('cylibs/trust/roles/buffer')

state.AutoAssaultMode = M{['description'] = 'Auto Assault Mode', 'Off', 'Auto'}
state.AutoPetMode = M{['description'] = 'Auto Pet Mode', 'Off', 'Auto'}

function BeastmasterTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Beastmaster.new(action_queue)), BeastmasterTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.self_buffs = trust_settings.SelfBuffs

	self.last_buff_time = os.time()

	return self
end

function BeastmasterTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_familiar(pet_util.get_pet().id, pet_util.get_pet().name)
	end

	self:get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				self:update_familiar(pet_id, pet_name)
			end)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
	end)
end

function BeastmasterTrust:destroy()
	Trust.destroy(self)
end

function BeastmasterTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_pet()
	self:check_buffs()

	if state.AutoAssaultMode.value ~= 'Off' and pet_util.has_pet() and pet_util.get_pet().status == 0 and self.target_index
			and windower.ffxi.get_mob_by_index(self.target_index) then
		local fight_action = JobAbilityAction.new(0, 0, 0, 'Fight', self.target_index)
		fight_action.priority = ActionPriority.highest
		self.action_queue:push_action(fight_action, true)
	end
end

function BeastmasterTrust:check_pet()
	if state.AutoPetMode.value == 'Off' or pet_util.has_pet() then
		return
	end
	self:get_job():bestial_loyalty()
end

function BeastmasterTrust:get_inactive_buffs()
	if self.familiar == nil then
		return L{}
	end
	return self.self_buffs:filter(function(buff)
		return buff.Familiar == self.familiar:get_mob().name and not buff_util.is_buff_active(buff_util.buff_id(buff.Buff))
	end)
end

function BeastmasterTrust:check_buffs()
	if state.AutoBuffMode.value == 'Off' or (os.time() - self.last_buff_time) < 8
			or self.familiar == nil or not self.familiar:is_engaged() then
		return
	end

	for buff in self:get_inactive_buffs():it() do
		local recast_id = res.job_abilities:with('en', buff.ReadyMove).recast_id
		if windower.ffxi.get_ability_recasts()[recast_id] == 0 then
			local actions = L{}

			actions:append(ReadyMoveAction.new(0, 0, 0, buff.ReadyMove))
			actions:append(WaitAction.new(0, 0, 0, 2))

			self.action_queue:push_action(SequenceAction.new(actions, 'ready_move'), true)

			self.last_buff_time = os.time()
			return
		end
	end
end

function BeastmasterTrust:update_familiar(pet_id, pet_name)
	if self.familiar then
		self.familiar:destroy()
		self.familiar = nil
	end
	if pet_id and self:get_job():is_jug_pet(pet_name) then
		self.familiar = Familiar.new(pet_id, self.action_queue)
		self.familiar:monitor()
	end
end

return BeastmasterTrust



