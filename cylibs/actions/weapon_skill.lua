local HasWeaponSkillCondition = require('cylibs/conditions/has_weapon_skill')

local Action = require('cylibs/actions/action')
local WeaponSkillAction = setmetatable({}, {__index = Action })
WeaponSkillAction.__index = WeaponSkillAction

function WeaponSkillAction.new(weapon_skill_name)
	local conditions = L{
		HasWeaponSkillCondition.new(weapon_skill_name),
		MinTacticalPointsCondition.new(1000),
		NotCondition.new(L{ HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'amnesia'}, false) }),
	}
	local self = setmetatable(Action.new(0, 0, 0, nil, conditions), WeaponSkillAction)

	self.weapon_skill_name = weapon_skill_name

	local target = self:get_target()
	if target and target.id ~= windower.ffxi.get_player().id then
		self:add_condition(MaxDistanceCondition.new(battle_util.get_weapon_skill_distance(weapon_skill_name, target.index), target.index))
	end

 	return self
end

function WeaponSkillAction:perform()
	local send_chat_input = function(weapon_skill_name)
		if L{ 'Moonlight', 'Myrkr', 'Dagan' }:contains(weapon_skill_name) then
			windower.chat.input("/ws %s <me>":format(weapon_skill_name))
		else
			windower.chat.input("/ws %s <t>":format(weapon_skill_name))
		end
	end

	send_chat_input(self.weapon_skill_name)

	self:complete(true)
end

function WeaponSkillAction:get_weapon_skill_name()
	return self.weapon_skill_name
end

function WeaponSkillAction:get_target()
	if L{ 'Moonlight', 'Myrkr', 'Dagan' }:contains(self:get_weapon_skill_name()) then
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
	if action == nil then
		return false
	end
	return self:gettype() == action:gettype() and self:get_weapon_skill_name() == action:get_weapon_skill_name()
end

function WeaponSkillAction:tostring()
	return self:get_weapon_skill_name()..' → '..self:get_target().name
end

function WeaponSkillAction:debug_string()
	return "WeaponSkillAction: %s":format(self:get_weapon_skill_name())
end

return WeaponSkillAction



