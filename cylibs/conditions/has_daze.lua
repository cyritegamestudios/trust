---------------------------
-- Condition checking whether an enemy has a daze active.
-- @class module
-- @name HasDazeCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local HasDazeCondition = setmetatable({}, { __index = Condition })
HasDazeCondition.__index = HasDazeCondition
HasDazeCondition.__type = "HasDazeCondition"
HasDazeCondition.__class = "HasDazeCondition"

function HasDazeCondition.new(daze_name, level, operator)
    local self = setmetatable(Condition.new(), HasDazeCondition)
    self.daze_name = daze_name or "Sluggish Daze"
    self.level = level or 1
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function HasDazeCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local monster = player.party:get_target(target.id)
        if monster then
            local daze_level = monster:get_step_tracker():get_daze_level(self.daze_name)
            return self:eval(daze_level, self.level, self.operator)
        end
    end
    return false
end

function HasDazeCondition:get_config_items()
    local all_dazes = L{ 'Sluggish Daze', 'Lethargic Daze', 'Weakened Daze' }

    return L{
        PickerConfigItem.new('daze_name', self.daze_name, all_dazes, nil, "Daze"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator"),
        ConfigItem.new('level', 1, 10, 1, nil, "Level")
    }
end

function HasDazeCondition:tostring()
    return "Has "..self.daze_name..' '..self.operator..' lv.'..self.level
end

function HasDazeCondition.description()
    return "Has daze."
end

function HasDazeCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function HasDazeCondition:serialize()
    return "HasDazeCondition.new(" .. serializer_util.serialize_args(self.daze_name, self.level, self.operator) .. ")"
end

return HasDazeCondition




