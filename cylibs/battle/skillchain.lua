---------------------------
-- Wrapper around a skillchain.
-- @class module
-- @name Skillchain

require('tables')
require('lists')
require('logger')
require('vectors')

local packets = require('packets')
local res = require('resources')

local Skillchain = {}
Skillchain.__index = Skillchain

function Skillchain.new(weapon_skills)
	local self = setmetatable({}, Skillchain)
	self.weapon_skills = weapon_skills
	self.skillchain_in_progress = false
	self.weapon_skill_in_progress = false
	return self
end

function Skillchain:can_perform()
	-- List of player names
	local skillchain_members = self.weapon_skills:map(function(weapon_skill)
		return weapon_skill.player
	end)

	-- Check party member TP
	for i, party_member in pairs(windower.ffxi.get_party()) do
        if type(party_member) == 'table' and party_member.mob and skillchain_members:contains(party_member.name) then
			if party_member.tp < 1000 then
				return false
			end
        end
    end

	-- Check player TP
	if windower.ffxi.get_player().vitals.tp < 1000 then
		return false
	end
	
	return true
end

function Skillchain:enable()
	if not self.user_events then
		self.user_events = {}
		self.user_events.tp_change = windower.register_event('time change', function(new_time, old_time)
			if not self.skillchain_in_progress then
				if self:can_perform() then
					self:begin_skillchain()
				end
			else
				-- Check to see if player's weapnon skill is next
				if not self.weapon_skill_in_progress and not self.weapon_skill_steps:empty() then
					local next_skillchain_step = self.weapon_skill_steps[1]
					
					local player_id = windower.ffxi.get_mob_by_name(next_skillchain_step.player).id
					if player_id == windower.ffxi.get_player().id then
						self.weapon_skill_in_progress = true
						self:perform_weapon_skill(next_skillchain_step.name)
					end
				end
			end
		end)
	end
end

function Skillchain:disable()
	notice("Skillchain: removing listeners")
	if self.user_events then
		for _,event in pairs(self.user_events) do
			windower.unregister_event(event)
		end
	end
end

function Skillchain:begin_skillchain()
	if self.skillchain_in_progress then
		return
	end
	
	notice("Beginning skillchain %s":format(self:tostring()))
	
	self.skillchain_in_progress = true
	self.weapon_skill_steps = self.weapon_skills:copy(true)
	
	self.user_events.action = windower.register_event('action', function(act)
		local next_skillchain_step = self.weapon_skill_steps[1]
		if not next_skillchain_step then
			notice("%s":format(self.weapon_skill_steps:tostring()))
			return
		end

		local category = act.category
		if category == 3 and act.actor_id and act.param and tonumber(act.param) then
			local player_id = windower.ffxi.get_mob_by_name(next_skillchain_step.player).id
			
			-- Validate weapon skill
			local weapon_skill_id = tonumber(act.param)
			local weapon_skill = res.weapon_skills[weapon_skill_id]
			if not weapon_skill or not weapon_skill.name then
				return
			end
			
			local weapon_skill_name = weapon_skill.name
			
			local actor_id = act.actor_id
			notice("%s performed %s":format(actor_id, weapon_skill_name))
			if actor_id == player_id and weapon_skill_name == next_skillchain_step.name then
				notice("Step complete: %s performed %s":format(next_skillchain_step.player, weapon_skill_name))
				
				coroutine.sleep(3)
				
				self.weapon_skill_steps:remove(1)
				
				if actor_id == windower.ffxi.get_player().id then
					self.weapon_skill_in_progress = false
				end
				
				if self.weapon_skill_steps:empty() then
					self:complete_skillchain()
				end
			end
		end
	end)
end

function Skillchain:complete_skillchain()
	notice("Skillchain complete")
	windower.unregister_event(self.user_events.action)
	self.weapon_skill_in_progress = false
	self.skillchain_in_progress = false
end

function Skillchain:perform_weapon_skill(weapon_skill)
	notice("Weapon skill %s":format(weapon_skill))
	if self.user_events.ws == nil then 
		notice("Adding weapon skill listener")
		self.user_events.ws = windower.register_event('action message',function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
			local player = windower.ffxi.get_player()
			if actor_id == player.id then
				-- Unable to use weapon skill
				if message_id == 89 or message_id == 90 then
					error("Unable to use weapon skill, retrying in 2")
					coroutine.sleep(2)
					if windower.ffxi.get_player().vitals.tp < 1000 then
						return
					end
					self:perform_weapon_skill(weapon_skill)
				end
			end
		end)
	end
	windower.chat.input("/ws \"%s\" <t>":format(weapon_skill))
end

function Skillchain:tostring()
	local result = "%s":format(self.weapon_skills:tostring())

	return "Skillchain: %s":format(result)
end

return Skillchain



