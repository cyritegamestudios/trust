---------------------------
-- Condition checking whether a spell's recast is ready.
-- @class module
-- @name SpellRecastReadyCondition

local serializer_util = require('cylibs/util/serializer_util')
local spell_util = require('cylibs/util/spell_util')

local Condition = require('cylibs/conditions/condition')
local SpellRecastReadyCondition = setmetatable({}, { __index = Condition })
SpellRecastReadyCondition.__index = SpellRecastReadyCondition
SpellRecastReadyCondition.__type = "SpellRecastReadyCondition"
SpellRecastReadyCondition.__class = "SpellRecastReadyCondition"

function SpellRecastReadyCondition.new(spell_id)
    local self = setmetatable(Condition.new(), SpellRecastReadyCondition)
    self.spell_id = spell_id or 23
    return self
end

function SpellRecastReadyCondition:is_satisfied(target_index)
    return spell_util.can_cast_spell(self.spell_id)
end

function SpellRecastReadyCondition:tostring()
    return res.spells[self.spell_id].en.." recast is ready"
end

function SpellRecastReadyCondition.description()
    return "Spell recast is ready."
end

function SpellRecastReadyCondition:serialize()
    return "SpellRecastReadyCondition.new(" .. serializer_util.serialize_args(self.spell_id) .. ")"
end

function SpellRecastReadyCondition:__eq(otherItem)
    return otherItem.__class == SpellRecastReadyCondition.__class
            and self.spell_id == otherItem.spell_id
end

return SpellRecastReadyCondition




