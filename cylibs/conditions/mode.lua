---------------------------
-- Condition checking whether a mode is equal to a value.
-- @class module
-- @name ModeCondition
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ModeCondition = setmetatable({}, { __index = Condition })
ModeCondition.__index = ModeCondition
ModeCondition.__class = "ModeCondition"
ModeCondition.__type = "ModeCondition"

function ModeCondition.new(mode_name, mode_value)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), ModeCondition)
    self.mode_name = mode_name or 'AutoBuffMode'
    self.mode_value = mode_value or 'Off'
    return self
end

function ModeCondition:is_satisfied(_)
    if state[self.mode_name] then
        return state[self.mode_name].value == self.mode_value
    end
    return false
end

function ModeCondition:get_config_items()
    local mode_value_item = PickerConfigItem.new('mode_value', self.mode_value, L(state[self.mode_name]:options()):sort(), nil, "Mode Value", function(configItemKey, configItemValue)
        if configItemKey == 'mode_name' then
            return L(state[configItemValue]:options()):sort()
        end
    end)
    local mode_name_item = PickerConfigItem.new('mode_name', self.mode_name, L(T(state):keyset()):sort(), nil, "Mode Name")
    mode_name_item:addDependency(mode_value_item)

    return L{
        mode_name_item,
        mode_value_item
    }
end

function ModeCondition:tostring()
    return self.mode_name..' is '..self.mode_value
end

function ModeCondition.description()
    return "Mode is set to X."
end

function ModeCondition:serialize()
    return "ModeCondition.new(" .. serializer_util.serialize_args(self.mode_name, self.mode_value) .. ")"
end

function ModeCondition:__eq(otherItem)
    return otherItem.__class == ModeCondition.__class
            and self.mode_name == otherItem.mode_name
            and self.mode_value == otherItem.mode_value
end

return ModeCondition