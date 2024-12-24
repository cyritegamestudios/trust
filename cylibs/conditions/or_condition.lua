---------------------------
-- Condition checking whether a list of conditions all return `false`.
-- @class module
-- @name OrCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local localization_util = require('cylibs/util/localization_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local OrCondition = setmetatable({}, { __index = Condition })
OrCondition.__index = OrCondition
OrCondition.__type = "OrCondition"
OrCondition.__class = "OrCondition"

function OrCondition.new(conditions, target_index)
    local self = setmetatable(Condition.new(target_index), OrCondition)
    self.conditions = conditions or L{}
    return self
end

function OrCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        for condition in self.conditions:it() do
            if condition:is_satisfied(target_index) then
                return true
            end
        end
    end
    return false
end

function OrCondition:get_config_items()
    if self.conditions:length() > 0 then
        return self.conditions[1]:get_config_items()
    end
    return nil
end

function OrCondition:tostring()
    return "Any of "..localization_util.commas(self.conditions:map(function(condition) return condition:tostring() end))
end

function OrCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function OrCondition:serialize()
    return "OrCondition.new(" .. serializer_util.serialize_args(self.conditions) .. ")"
end

return OrCondition




