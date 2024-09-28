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
    local target
    if target_index == windower.ffxi.get_player().index then
        if windower.ffxi.get_player().target_index then
            target = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
        end
    else
        local enemy = player.party:get_target_by_index(target_index)
        if enemy then
            target = enemy.current_target
        end
    end
    if target and target.name == self.name then
        return true
    end
    return false
end

function TargetNameCondition:get_config_items()
    return L{ TextInputConfigItem.new('name', self.name, 'Target Name', function(_) return true  end) }
end

function TargetNameCondition:tostring()
    return "Target is "..self.name
end

function TargetNameCondition.description()
    return "Targeting mob with name."
end

function TargetNameCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy }
end

function TargetNameCondition:serialize()
    return "TargetNameCondition.new(" .. serializer_util.serialize_args(self.name) .. ")"
end

return TargetNameCondition




