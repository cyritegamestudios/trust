local serializer_util = require('cylibs/util/serializer_util')

---------------------------
-- Wrapper around a weapon skill.
-- @class module
-- @name WeaponSkill

local res = require('resources')

local WeaponSkill = {}
WeaponSkill.__index = WeaponSkill
WeaponSkill.__type = "WeaponSkill"

-------
-- Default initializer for a new weapon skill.
-- @tparam string weapon_skill_name Localized name of the weapon skill (see res/weapon_skills.lua)
-- @treturn WeaponSkill A weapon skill
function WeaponSkill.new(weapon_skill_name)
    local self = setmetatable({
        weapon_skill_name = weapon_skill_name;
        weapon_skill_id = res.weapon_skills:with('en', weapon_skill_name).id;
    }, WeaponSkill)

    return self
end

-------
-- Returns the name of the weapon skill.
-- @treturn string Name of the weapon skill (see res/weapon_skills.lua)
function WeaponSkill:get_name()
    return self.weapon_skill_name
end

-------
-- Returns the id of the weapon skill.
-- @treturn number Id of the weapon skill (see res/weapon_skills.lua)
function WeaponSkill:get_id()
    return self.weapon_skill_id
end

function WeaponSkill:serialize()
    return "WeaponSkill.new(" .. serializer_util.serialize_args(self.weapon_skill_name) .. ")"
end

function WeaponSkill:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_id() == self:get_id() then
        return true
    end
    return false
end

return WeaponSkill