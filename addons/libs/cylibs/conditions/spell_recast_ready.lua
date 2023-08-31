---------------------------
-- Condition checking whether a spell's recast is ready.
-- @class module
-- @name SpellRecastReadyCondition

local Condition = require('cylibs/conditions/condition')
local SpellRecastReadyCondition = setmetatable({}, { __index = Condition })
SpellRecastReadyCondition.__index = SpellRecastReadyCondition

function SpellRecastReadyCondition.new(spell_id)
    local self = setmetatable(Condition.new(), SpellRecastReadyCondition)
    self.spell_id = spell_id
    return self
end

function SpellRecastReadyCondition:is_satisfied(target_index)
    return spell_util.can_cast_spell(self.spell_id)
end

function SpellRecastReadyCondition:tostring()
    return "SpellRecastReadyCondition"
end

return SpellRecastReadyCondition




