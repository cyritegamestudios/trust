local HasWeaponSkillCondition = require('cylibs/conditions/has_weapon_skill')
local WeaponSkillCommand = require('cylibs/ui/input/chat/commands/weapon_skill')

local Action = require('cylibs/actions/action')
local WeaponSkillAction = setmetatable({}, {__index = Action })
WeaponSkillAction.__index = WeaponSkillAction
WeaponSkillAction.__type = "WeaponSkillAction"

function WeaponSkillAction.new(weapon_skill_name, target_index)
	local conditions = L{
		HasWeaponSkillCondition.new(weapon_skill_name),
		MinTacticalPointsCondition.new(1000, windower.ffxi.get_player().index),
		NotCondition.new(L{ HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'amnesia', 'stun'}, 1) }, windower.ffxi.get_player().index),
		ValidTargetCondition.new()
	}

	local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), WeaponSkillAction)

	self.weapon_skill_name = weapon_skill_name

	if res.weapon_skills:with('en', weapon_skill_name).targets:contains('Self') then
		target_index = windower.ffxi.get_player().index
		self.target_index = target_index
	end

	if target_index ~= windower.ffxi.get_player().index then
		self:add_condition(MaxDistanceCondition.new(battle_util.get_weapon_skill_distance(weapon_skill_name, target_index), target_index))
	end

 	return self
end

function WeaponSkillAction:perform()
	local target = windower.ffxi.get_mob_by_index(self.target_index)

	local command = WeaponSkillCommand.new(self.weapon_skill_name, target.id)
	command:run(true)

	self:complete(true)
end

function WeaponSkillAction:get_weapon_skill_name()
	return self.weapon_skill_name
end

function WeaponSkillAction:get_localized_name()
	return i18n.resource('weapon_skills', 'en', self:get_name())
end

function WeaponSkillAction:get_target()
	return windower.ffxi.get_mob_by_index(self.target_index)
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
	local target = self:get_target()
	if target then
		return self:get_weapon_skill_name()..' → '..self:get_target().name
	else
		return ""
	end
end

function WeaponSkillAction:debug_string()
	return "WeaponSkillAction: %s":format(self:get_weapon_skill_name())
end

return WeaponSkillAction



