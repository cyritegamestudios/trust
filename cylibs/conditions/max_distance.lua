---------------------------
-- Condition checking whether the target's distance <= distance.
-- @class module
-- @name MaxDistanceCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxDistanceCondition = setmetatable({}, { __index = Condition })
MaxDistanceCondition.__index = MaxDistanceCondition
MaxDistanceCondition.__class = "MaxDistanceCondition"
MaxDistanceCondition.__type = "MaxDistanceCondition"

function MaxDistanceCondition.new(distance, target_index, position)
    local self = setmetatable(Condition.new(target_index), MaxDistanceCondition)
    self.distance = distance or 20
    self.position = position
    return self
end

function MaxDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        if target.index == windower.ffxi.get_player().index then
            return true
        else
            if self.position then
                local distance = math.sqrt((self.position[1]-target.x)^2+(self.position[2]-target.y)^2)
                return distance <= self.distance
            else
                return target.valid_target and target.distance:sqrt() <= self.distance
            end
        end
    end
    return false
end

function MaxDistanceCondition:get_config_items()
    return L{
        ConfigItem.new('distance', 0, 50, 1, function(value) return value.." yalms" end, "Target Distance"),
    }
end

function MaxDistanceCondition:tostring()
    return "Target distance <= "..self.distance.. " yalms"
end

function MaxDistanceCondition.description()
    return "Target distance <= X yalms from player."
end

function MaxDistanceCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function MaxDistanceCondition:serialize()
    return "MaxDistanceCondition.new(" .. serializer_util.serialize_args(self.distance) .. ")"
end

return MaxDistanceCondition




