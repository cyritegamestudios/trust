require('actions')
require('math')
require('logger')
require('lists')

local job_util = require('cylibs/util/job_util')

local Action = require('cylibs/actions/action')
local WeaponSkillAction = setmetatable({}, {__index = Action })
WeaponSkillAction.__index = WeaponSkillAction

function WeaponSkillAction.new(weapon_skill_name)
	local conditions = L{
		NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'amnesia'}, false)}),
	}

	local self = setmetatable(Action.new(0, 0, 0, nil, conditions), WeaponSkillAction)

	self.weapon_skill_name = weapon_skill_name
	self.user_events = {}

 	return self
end

function WeaponSkillAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	if windower.ffxi.get_player().vitals.tp < 1000
			or not job_util.knows_weapon_skill(self.weapon_skill_name) then
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
		if L{ 'Moonlight', 'Myrkr', 'Dagan' }:contains(weapon_skill_name) then
			windower.chat.input("/ws \"%s\" <me>":format(weapon_skill_name))
		else 
			windower.chat.input("/ws \"%s\" <t>":format(weapon_skill_name))
		end
	end

	--[[
		self.dispose_bag:add(WindowerEvents.Action:addAction(function(packet)
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
	end), WindowerEvents.Action)


	self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
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
	end), WindowerEvents.ActionMessage)
	]]
	
	send_chat_input(res.weapon_skills:with('en', weapon_skill_name).name)

	--coroutine.sleep(3)

	self:complete(true)
end

function WeaponSkillAction:get_weapon_skill_name()
	return self.weapon_skill_name
end

function WeaponSkillAction:get_target()
	if L{ 'Moonlight', 'Myrkr' }:contains(self:get_weapon_skill_name()) then
		return windower.ffxi.get_player()
	else
		return windower.ffxi.get_mob_by_target('t')
	end
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
	return self:get_weapon_skill_name()..' → '..self:get_target().name
end

function WeaponSkillAction:debug_string()
	return "WeaponSkillAction: %s":format(self:get_weapon_skill_name())
end

return WeaponSkillAction



