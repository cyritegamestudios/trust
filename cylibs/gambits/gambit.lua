local serializer_util = require('cylibs/util/serializer_util')

local Gambit = {}
Gambit.__index = Gambit
Gambit.__class = "Gambit"

function Gambit.new(target, conditions, reaction)
    local self = setmetatable({}, Gambit)

    self.target = target
    self.conditions = conditions
    self.reaction = reaction

    return self
end

function Gambit:isSatisfied(target)
    return Condition.check_conditions(self.conditions, target:get_mob().index)
end

function Gambit:getAction(target, dependency_container)
    return self.reaction:getAction(target, dependency_container)
end

function Gambit:serialize()
    local conditions = serializer_util.serialize(self.conditions, 0)
    return "Gambit.new(" .. self.target:serialize() .. ", " .. conditions .. ", " .. self.reaction:serialize() .. ")"
end

return Gambit