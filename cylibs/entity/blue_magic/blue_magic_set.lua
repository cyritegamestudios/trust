---------------------------
-- Represents a blue magic set.
-- @class module
-- @name BlueMagicSet
local serializer_util = require('cylibs/util/serializer_util')

local BlueMagicSet = {}
BlueMagicSet.__index = BlueMagicSet
BlueMagicSet.__type = "BlueMagicSet"
BlueMagicSet.__class = "BlueMagicSet"

function BlueMagicSet.new(spells)
    local self = setmetatable({}, BlueMagicSet)
    self.spells = spells or L{}
    return self
end

function BlueMagicSet:getSpells()
    return self.spells
end

function BlueMagicSet:tostring()
    return "Spells: "..self.spells:tostring()
end

function BlueMagicSet:serialize()
    return "BlueMagicSet.new(" .. serializer_util.serialize_args(self.spells) .. ")"
end

return BlueMagicSet




