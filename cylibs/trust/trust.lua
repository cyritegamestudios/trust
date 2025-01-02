require('tables')
require('lists')
require('logger')

local Event = require('cylibs/events/Luvent')

local Trust = {}
Trust.__index = Trust
Trust.__class = "Trust"

-- Event called when trust settings are changed.
function Trust:on_trust_settings_changed()
	return self.trust_settings_changed
end

-- Event called when trust roles are changed.
function Trust:on_trust_roles_changed()
	return self.trust_roles_changed
end

function Trust.new(action_queue, roles, trust_settings, job)
	local self = setmetatable({
		action_queue = action_queue;
		roles = roles;
		trust_settings = trust_settings;
		job = job;
		user_events = {};
		status = 0;
		role_blacklist = S{};
		gambits = L{};
		trust_settings_changed = Event.newEvent();
		trust_roles_changed = Event.newEvent();
		trust_modes_override = Event.newEvent();
		trust_modes_reset = Event.newEvent();
	}, Trust)

	self.gambits = trust_settings.GambitSettings.Default or L{}

	return self
end

function Trust:init()
	for role in self.roles:it() do
		self:add_role(role)
	end
	self:on_init()

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local gambiter = self:role_with_type("gambiter")
		if gambiter then
			gambiter:set_gambit_settings(new_trust_settings.GambitSettings)
		end
		local targeter = self:role_with_type("targeter")
		if targeter then
			targeter:set_target_settings(new_trust_settings.TargetSettings)
		end
		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_buff_settings(new_trust_settings.BuffSettings)
		end

		self.gambits = new_trust_settings.GambitSettings.Default or L{}
	end)

	self.on_party_target_change_id = self.party:on_party_target_change():addAction(
			function(_, new_target_index, old_target_index)
				if new_target_index == old_target_index then
					logger.notice(self.__class, 'on_party_target_change', 'same target index')
					return
				end
				logger.notice(self.__class, 'on_party_target_change', new_target_index or 'nil', old_target_index or 'nil')
				self.action_queue:cleanup()
				self.target_index = new_target_index
				self:job_target_change(new_target_index, old_target_index)
			end)

	local party_target = self.party:get_current_party_target()
	if party_target and party_target:get_mob() then
		self.target_index = party_target:get_mob().index
		self:job_target_change(self.target_index, nil)
	end
end

function Trust:destroy()
	for role in self.roles:it() do
		if role.destroy then
			role:destroy()
			role:set_player(nil)
			role:set_alliance(nil)
			role:set_party(nil)
		end
	end

	self.trust_settings_changed:removeAllActions()
	self.trust_roles_changed:removeAllActions()
	self.trust_modes_override:removeAllActions()
	self.trust_modes_reset:removeAllActions()

	self:on_deinit()

	self.player:destroy()
	self.player = nil
end

function Trust:on_init()
	for party in self:get_alliance():get_parties():it() do
		if party:get_player() == nil then
			party:on_party_member_added():addAction(function(p)
				for role in self.roles:it() do
					if role.get_party_member_blacklist then
						role:get_party_member_blacklist():append(p:get_name())
					end
				end
			end)
			party:on_party_member_removed():addAction(function(p)
				for role in self.roles:it() do
					if role.get_party_member_blacklist then
						role:set_party_member_blacklist(role:get_party_member_blacklist():filter(function(party_member_name)
							return party_member_name ~= p:get_name()
						end))
					end
				end
			end)
		end
	end
end

function Trust:on_deinit()
end

function Trust:on_role_added(role)
end

function Trust:add_role(role)
	if self.role_blacklist:contains(role:get_type()) then
		return
	end
	self.roles:add(role)

	if role.on_add then
		role:set_player(self.player)
		role:set_alliance(self.alliance)
		role:set_party(self.party)
		role:on_add()
		if role.target_change then
			role:target_change(self.target_index)
		end
		self:on_role_added(role)
	end
	self:on_trust_roles_changed():trigger(self, L{ role })
end

function Trust:remove_role(role)
	if role.destroy then
		role:destroy()
		role:set_player(nil)
		role:set_party(nil)
	end
	self.roles = self.roles:filter(function(r) return r:get_type() ~= role:get_type() end)
end

function Trust:replace_role(role_type, new_role)
	local old_role = self:role_with_type(role_type)
	if old_role then
		self:remove_role(old_role)
	end
	self:add_role(new_role)
end

function Trust:blacklist_role(role_type)
	self.role_blacklist:add(role_type)
end

function Trust:is_blacklisted(role_type)
	return self.role_blacklist:contains(role_type)
end

function Trust:role_with_type(role_type)
	for role in self.roles:it() do
		if role:get_type() == role_type then
			return role
		end
	end
	return nil
end

function Trust:roles_with_types(role_types)
	local roles = L{}
	for role_type in role_types:it() do
		local role = self:role_with_type(role_type)
		if role then
			roles:append(role)
		end
	end
	return roles
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

function Trust:job_target_change(target_index)
	for role in self.roles:it() do
		if role.target_change then
			role:target_change(target_index)
		end
	end
end

function Trust:tic(old_time, new_time)
	local tic_time = os.time()
	for role in self.roles:it() do
		role:set_last_tic_time(tic_time)
		if role.tic then
			role:tic(old_time, new_time)
		end
	end
end

function Trust:job_status_change(new_status)
	self.status = new_status
end

function Trust:check_gambits(gambits)
	local gambiter = self:role_with_type("gambiter")
	if gambiter then
		gambiter:check_gambits(nil, gambits)
	end
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

function Trust:set_alliance(alliance)
	self.alliance = alliance
end

function Trust:get_alliance()
	return self.alliance
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

function Trust:get_target_index()
	return self.target_index
end

function Trust:get_target()
	return self:get_party():get_target_by_index(self.target_index)
end

function Trust:set_trust_settings(trust_settings)
	local old_trust_settings = self.trust_settings
	self.trust_settings = trust_settings

	self:on_trust_settings_changed():trigger(old_trust_settings, trust_settings)
end

function Trust:get_trust_settings()
	return self.trust_settings
end

return Trust



