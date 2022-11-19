require('tables')
require('lists')
require('logger')

local Trust = {}
Trust.__index = Trust

function Trust.new(action_queue, roles, trust_settings, job)
	local self = setmetatable({
		action_queue = action_queue;
		roles = roles;
		trust_settings = trust_settings;
		job = job;
		user_events = {};
		status = 0;
		battle_target = nil;
	}, Trust)

	return self
end

function Trust:init()
	for role in self.roles:it() do
		role:set_player(self.player)
		role:set_party(self.party)
		if role.on_add then
			role:on_add()
		end
	end
	self:on_init()

	self.on_party_target_change_id = self.party:on_party_target_change():addAction(
			function(_, new_target_index, old_target_index)
				if new_target_index == old_target_index then
					return
				end
				self.action_queue:clear()
				self:job_target_change(new_target_index)
			end)
end

function Trust:destroy()
	for role in self.roles:it() do
		if role.destroy then
			role:set_player(nil)
			role:set_party(nil)
			role:destroy()
		end
	end

	self.player:destroy()
	self.player = nil
end

function Trust:on_init()
end

function Trust:add_role(role)
	self.roles:add(role)

	if role.on_add then
		role:set_player(self.player)
		role:set_party(self.party)
		role:on_add()
	end
end

function Trust:remove_role(role)
	if role.destroy then
		role:destroy()
		role:set_player(nil)
		role:set_party(nil)
	end
	self.roles = self.roles:filter(function(r) return r:get_type() ~= role:get_type() end)
end

function Trust:job_magic_burst(target_id, spell)
	for role in self.roles:it() do
		if role.job_magic_burst then
			role:job_magic_burst(target_id, spell)
		end
	end
end

function Trust:job_weapon_skill(weapon_skill_name)
	for role in self.roles:it() do
		if role.job_weapon_skill then
			role:job_weapon_skill(weapon_skill_name)
		end
	end
end

function Trust:job_filtered_action(spell, eventArgs)
end

function Trust:job_pretarget(spell, spellMap, eventArgs)
end

function Trust:job_target_change(target_index)
	for role in self.roles:it() do
		if role.target_change then
			role:target_change(target_index)
		end
	end
end

function Trust:job_precast(spell, spellMap, eventArgs)
end

function Trust:job_post_midcast(spell, spellMap, eventArgs)
end

function Trust:job_midcast(spell, action, spellMap, eventArgs)
end

function Trust:job_buff_change(buff, gain)
end

function Trust:job_post_precast(spell, spellMap, eventArgs)
end

function Trust:tic(old_time, new_time)
	for role in self.roles:it() do
		if role.tic then
			role:tic(old_time, new_time)
		end
	end
end

function Trust:job_status_change(new_status)
	self.status = new_status
end

function Trust:set_player(player)
	self.player = player
end

function Trust:get_player()
	return self.player
end

-------
-- Returns the job for this Trust
-- @treturn Job Job for this Trust
function Trust:get_job()
	return self.job
end

function Trust:set_party(party)
	self.party = party
end

function Trust:get_party()
	return self.party
end

function Trust:get_roles()
	return self.roles
end

function Trust:get_trust_settings()
	return self.trust_settings
end

return Trust



