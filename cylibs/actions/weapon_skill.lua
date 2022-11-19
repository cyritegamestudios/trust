--[[Copyright © 2019, Cyrite

Engage v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

require('actions')
require('math')
require('logger')
require('lists')

local packets = require('packets')

local Action = require('cylibs/actions/action')
local WeaponSkillAction = setmetatable({}, {__index = Action })
WeaponSkillAction.__index = WeaponSkillAction

function WeaponSkillAction.new(weapon_skill_name)
	local self = setmetatable(Action.new(0, 0, 0), WeaponSkillAction)
	self.weapon_skill_name = weapon_skill_name
	self.user_events = {}
 	return self
end

function WeaponSkillAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	if windower.ffxi.get_player().vitals.tp < 1000 then
		return false
	end
	return true
end

function WeaponSkillAction:perform()
	self:perform_weapon_skill(self:get_weapon_skill_name())
end

function WeaponSkillAction:complete(success)
	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
	Action.complete(self, success)
end

function WeaponSkillAction:perform_weapon_skill(weapon_skill_name)
	local send_chat_input = function(weapon_skill_name)
		if L{ 'Moonlight', 'Myrkr' }:contains(weapon_skill_name) then
			windower.chat.input("/ws \"%s\" <me>":format(weapon_skill_name))
		else 
			windower.chat.input("/ws \"%s\" <t>":format(weapon_skill_name))
		end
	end

	--[[self.user_events.action = windower.register_event('action', function(packet)
		if self:is_cancelled() then
			self:complete(false)
			return
		end

		local action_packet = ActionPacket.new(packet)
		if action_packet ~= nil then
			local actor = windower.ffxi.get_mob_by_id(action_packet:get_id())
			if actor == nil then
				self:complete(false)
				return
			end
			if actor.name == windower.ffxi.get_player().name then
				local category_string = action_packet:get_category_string()
				for target in action_packet:get_targets() do
					for action in target:get_actions() do
						param, resource, spell_id, interruption, conclusion = action:get_spell()
						if spell_id and resource then
							local weapon_skill = res[resource]:with('id', spell_id)

							if weapon_skill.name == self.weapon_skill_name then
								if category_string == 'weaponskill_begin' then
									self:complete(true)
								end
								if interruption then
									self:complete(false)
								end
							end
						else
							self:complete(false)
							return
						end
					end
				end
			end
		end
	end)


	self.user_events.ws = windower.register_event('action message', function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		local failure_message_ids = L{ 5, 84, 90, 217, 219 }
		local success_message_ids = L{ 6 }

		local player = windower.ffxi.get_player()
		if actor_id == player.id then
			
			-- Unable to use weapon skill
			if failure_message_ids:contains(message_id) then
				--error("Unable to use weapon skill, retrying in 2")
				--coroutine.sleep(2)
				--if windower.ffxi.get_player().vitals.tp < 1000 then
				--	self:complete(false)
				--	return
				--end
				--send_chat_input(weapon_skill_name)
				self:complete(false)

			--elseif success_message_ids:contains(message_id) then
			--	notice("Finished weapon skill")
			--	coroutine.sleep(3)
			--	self:complete(true)
			end
		end
	end)]]
	
	send_chat_input(weapon_skill_name)

	--coroutine.sleep(3)

	self:complete(true)
end

function WeaponSkillAction:get_weapon_skill_name()
	return self.weapon_skill_name
end

function WeaponSkillAction:gettype()
	return "weaponskillaction"
end

function WeaponSkillAction:getrawdata()
	local res = {}
	res.weaponskillaction = {}
	return res
end

function WeaponSkillAction:is_equal(action)
	if action == nil then return false end

	return self:gettype() == action:gettype() and self:get_weapon_skill_name() == action:get_weapon_skill_name()
end

function WeaponSkillAction:tostring()
    return "WeaponSkillAction: %s":format(self:get_weapon_skill_name())
end

return WeaponSkillAction



