---------------------------
-- Condition checking whether the knows a weapon skill.
-- @class module
-- @name HasWeaponSkillCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasWeaponSkillCondition = setmetatable({}, { __index = Condition })
HasWeaponSkillCondition.__index = HasWeaponSkillCondition
HasWeaponSkillCondition.__class = "HasWeaponSkillCondition"

function HasWeaponSkillCondition.new(weapon_skill_name)
    local self = setmetatable(Condition.new(), HasWeaponSkillCondition)
    self.weapon_skill_name = weapon_skill_name
    return self
end

function HasWeaponSkillCondition:is_satisfied(target_index)
    return job_util.knows_weapon_skill(self.weapon_skill_name)
end

function HasWeaponSkillCondition:tostring()
    return "HasWeaponSkillCondition"
end

function HasWeaponSkillCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function HasWeaponSkillCondition:serialize()
    return "HasWeaponSkillCondition.new(" .. serializer_util.serialize_args(self.weapon_skill_name) .. ")"
end

function HasWeaponSkillCondition:__eq(otherItem)
    return otherItem.__class == HasWeaponSkillCondition.__class
            and self.weapon_skill_name == otherItem.weapon_skill_name
end

return HasWeaponSkillCondition