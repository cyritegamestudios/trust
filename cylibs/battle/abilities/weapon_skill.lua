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
-- @treturn WeaponSkill A weapon skill
function WeaponSkill.new(weapon_skill_name)
    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill == nil then
        return nil
    end
    local self = setmetatable(SkillchainAbility.new('weapon_skills', weapon_skill.id), WeaponSkill)
    return self
end

function WeaponSkill:serialize()
    return "WeaponSkill.new(" .. serializer_util.serialize_args(self:get_name()) .. ")"
end

function WeaponSkill:__eq(otherItem)
    if otherItem.__class == WeaponSkill._class and otherItem:get_ability_id() == self:get_ability_id() then
        return true
    end
    return false
end

return WeaponSkill