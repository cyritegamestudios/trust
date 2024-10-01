---------------------------
-- Wrapper around a BST ready move.
-- @class module
-- @name ReadyMove

local res = require('resources')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local ReadyMove = setmetatable({}, {__index = SkillchainAbility })
ReadyMove.__index = ReadyMove
ReadyMove.__type = "ReadyMove"
ReadyMove.__class = "ReadyMove"

-------
-- Default initializer for a ready move.
-- @tparam string weapon_skill_name Localized name of the weapon skill (see res/weapon_skills.lua)
-- @treturn ReadyMove A ready move
function ReadyMove.new(ready_move_name)
    local ready_move = res.job_abilities:with('en', ready_move_name)
    if ready_move == nil then
        return nil
    end
    local self = setmetatable(SkillchainAbility.new('job_abilities', ready_move.id), ReadyMove)
    return self
end

function ReadyMove:serialize()
    return "ReadyMove.new(" .. serializer_util.serialize_args(self:get_name()) .. ")"
end

function ReadyMove:__eq(otherItem)
    if otherItem.__class == ReadyMove._class and otherItem:get_ability_id() == self:get_ability_id() then
        return true
    end
    return false
end

return ReadyMove