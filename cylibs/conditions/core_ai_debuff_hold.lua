---------------------------
-- Condition that is satisfied unless CoreAI's debuff hold is
-- active. Added by the Debuffer to every debuff gambit: when
-- satisfied (the default), debuffs cast exactly as before; when
-- the debuff_hold extension module sets the hold (player TP at or
-- above its threshold), debuffs wait until the weaponskill has
-- been used and TP drops.
--
-- The hold flag lives on the shared CoreAI table
-- (cylibs/trust/extensions/core_ai.lua) and is only ever set by the
-- debuff_hold module when its DEBUFF_HOLD_ENABLED flag is on. This
-- file fails OPEN: if CoreAI cannot be loaded or read, the
-- condition is satisfied and behaviour is exactly as before CoreAI
-- existed.
-- @class module
-- @name CoreAIDebuffHoldCondition

local Condition = require('cylibs/conditions/condition')
local CoreAIDebuffHoldCondition = setmetatable({}, { __index = Condition })
CoreAIDebuffHoldCondition.__index = CoreAIDebuffHoldCondition
CoreAIDebuffHoldCondition.__class = "CoreAIDebuffHoldCondition"
CoreAIDebuffHoldCondition.__type = "CoreAIDebuffHoldCondition"

function CoreAIDebuffHoldCondition.new(target_index)
    local self = setmetatable(Condition.new(target_index), CoreAIDebuffHoldCondition)
    return self
end

function CoreAIDebuffHoldCondition:is_satisfied(target_index)
    local ok, core_ai = pcall(require, 'cylibs/trust/extensions/core_ai')
    if ok and core_ai and core_ai.debuff_hold then
        return false
    end
    return true
end

function CoreAIDebuffHoldCondition:tostring()
    return "CoreAI debuff hold not active"
end

function CoreAIDebuffHoldCondition.description()
    return "No CoreAI debuff hold is active."
end

function CoreAIDebuffHoldCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

return CoreAIDebuffHoldCondition
