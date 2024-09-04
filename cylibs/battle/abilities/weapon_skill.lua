---------------------------
-- Wrapper around a weapon skill.
-- @class module
-- @name WeaponSkill

local res = require('resources')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local WeaponSkill = setmetatable({}, {__index = SkillchainAbility })
WeaponSkill.__index = WeaponSkill
WeaponSkill.__type = "WeaponSkill"
WeaponSkill.__class = "WeaponSkill"

-------
-- Default initializer for a new weapon skill.
-- @tparam string weapon_skill_name Localized name of the weapon skill (see res/weapon_skills.lua)
-- @tparam list conditions (optional) List of conditions that must be met to use this ability
-- @treturn WeaponSkill A weapon skill
function WeaponSkill.new(weapon_skill_name, conditions)
    conditions = conditions or L{}
    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill == nil then
        return nil
    end
    local matches = conditions:filter(function(c)
        return c.__class == MinTacticalPointsCondition.__class
    end)
    if matches:length() == 0 then
        conditions:append(MinTacticalPointsCondition.new(1000))
    end
    local skillchain_ability = SkillchainAbility.new('weapon_skills', weapon_skill.id, conditions)
    if skillchain_ability == nil then
        return nil
    end
    local self = setmetatable(skillchain_ability, WeaponSkill)
    return self
end

--[[function WeaponSkill:to_action(target_index, _)
    local action = WeaponSkillAction.new(self:get_name(), target_index)
    action.identifier = self.__class..'_'..self:get_name()
    return action
end]]

function WeaponSkill:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "WeaponSkill.new(" .. serializer_util.serialize_args(self:get_name(), conditions_to_serialize) .. ")"
end

function WeaponSkill:__eq(otherItem)
    if not L{ SkillchainAbility.__class, WeaponSkill.__class }:contains(otherItem.__class) then
        return false
    end
    return otherItem:get_name() == self:get_name()
end

return WeaponSkill