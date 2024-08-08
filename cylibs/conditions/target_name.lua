---------------------------
-- Condition checking the target's name.
-- @class module
-- @name TargetNameCondition
local serializer_util = require('cylibs/util/serializer_util')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local Condition = require('cylibs/conditions/condition')
local TargetNameCondition = setmetatable({}, { __index = Condition })
TargetNameCondition.__index = TargetNameCondition
TargetNameCondition.__class = "TargetNameCondition"
TargetNameCondition.__type = "TargetNameCondition"

function TargetNameCondition.new(name)
    local self = setmetatable(Condition.new(), TargetNameCondition)
    self.name = name or "Spiny Spipi"
    return self
end

function TargetNameCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and target.name == name then
        return true
    end
    return false
end

function TargetNameCondition:get_config_items()
    return L{ TextInputConfigItem.new('name', self.name, 'Target Name', function(_) return true  end) }
end

function TargetNameCondition:tostring()
    return "Target is "..self.name.."."
end

function TargetNameCondition.description()
    return "Targeting a specific enemy."
end

function TargetNameCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function TargetNameCondition:serialize()
    return "TargetNameCondition.new(" .. serializer_util.serialize_args(self.name) .. ")"
end

return TargetNameCondition




