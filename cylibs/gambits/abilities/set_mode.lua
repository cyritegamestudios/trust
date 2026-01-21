---------------------------
-- Action representing setting a mode value.
-- @class module
-- @name SetMode

local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local SetMode = {}
SetMode.__index = SetMode
SetMode.__type = "SetMode"
SetMode.__class = "SetMode"

-------
-- Default initializer for a new set mode.
-- @treturn SetMode A turn around.
function SetMode.new(mode_name, mode_value, conditions)
    local self = setmetatable({}, SetMode)

    local all_mode_names = L(T(state):keyset()):sort()

    self.mode_name = mode_name or all_mode_names[1]
    self.mode_value = mode_value or L(state[all_mode_names[1]]:options())[1]
    self.conditions = conditions or L{}

    return self
end

function SetMode:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function SetMode:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions.
-- @treturn list List of conditions
function SetMode:get_conditions()
    return self.conditions + L{}
end

-------
-- Returns the list of default conditions.
-- @treturn list List of default conditions
function SetMode:get_default_conditions()
    local mode_condition = NotCondition.new(L{ ModeCondition.new(self.mode_name, self.mode_value) })
    mode_condition.editable = false
    return L{ mode_condition }
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function SetMode:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function SetMode:get_name()
    return 'Set Mode'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function SetMode:get_localized_name()
    return 'Set Mode'
end

-------
-- Returns the display name.
-- @treturn string Display name
function SetMode:get_display_name()
    return string.format("Set %s to %s", self.mode_name, self.mode_value)
end

-------
-- Returns the config items that will be used when creating the config editor
-- to edit this ability.
-- @treturn list List of ConfigItem
function SetMode:get_config_items()
    local all_mode_names = L(T(state):keyset()):sort()

    local mode_value_item = PickerConfigItem.new('mode_value', self.mode_value, state[self.mode_name]:options(), nil, "Mode Value")
    mode_value_item.onReload = function(key, newValue, configItem)
        return state[newValue]:options()
    end

    local mode_name_item = PickerConfigItem.new('mode_name', self.mode_name, all_mode_names, nil, "Mode Name")
    mode_name_item:addDependency(mode_value_item)

    return L{
        mode_name_item,
        mode_value_item
    }
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function SetMode:to_action(_, _)
    return BlockAction.new(function()
        local mode = state[self.mode_name]
        if mode and mode.value ~= self.mode_value then
            mode:set(self.mode_value)
        end
    end, string.format("Set %s to %s", self.mode_name, self.mode_value), self.__class..'_'..self.mode_name..'_'..self.mode_value)
end

function SetMode:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "SetMode.new(" .. serializer_util.serialize_args(self.mode_name, self.mode_value, conditions_to_serialize) .. ")"
end

function SetMode:is_valid()
    return true
end

function SetMode:copy()
    return SetMode.new(self.mode_name, self.mode_value, self.conditions:copy())
end

function SetMode:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return SetMode