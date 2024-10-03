---------------------------
-- Action to use an item.
-- @class module
-- @name UseItem

local inventory_util = require('cylibs/util/inventory_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local UseItem = {}
UseItem.__index = UseItem
UseItem.__class = "UseItem"
UseItem.__type = "UseItem"

-------
-- Default initializer for a new use item.
-- @treturn UseItem A use item action.
function UseItem.new(item_name, conditions, description)
    local self = setmetatable({}, UseItem)

    self.item_name = item_name or 'Grape Daifuku'
    self.conditions = conditions or L{}
    self.description = description

    local item_count_condition = (conditions or L{}):filter(function(condition) return condition.__type == ItemCountCondition.__type end)
    if item_count_condition:length() == 0 then
        self:add_condition(ItemCountCondition.new(item_name, 1, Condition.Operator.GreaterThanOrEqualTo))
    end

    return self
end

function UseItem:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function UseItem:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions.
-- @treturn list List of conditions
function UseItem:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function UseItem:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function UseItem:get_name()
    return 'Use Item'
end

function UseItem:get_display_name()
    return self.description or 'Use '..self.item_name
end

function UseItem:__tostring()
    return 'Use '..self.item_name
end

function UseItem:get_item_name()
    return self.item_name
end

function UseItem:get_config_items()
    local item_names = L{}
    for _, item in pairs(inventory_util.all_items()) do
        item_names:append(item.en)
    end
    item_names = L(S(item_names)):sort()
    return L{ PickerConfigItem.new('item_name', self.item_name, item_names, nil, "Item Name") }
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function UseItem:to_action(target_index, _)
    return CommandAction.new(0, 0, 0, '/item \"'..self.item_name..'\" <me>')
end

function UseItem:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "UseItem.new(" .. serializer_util.serialize_args(self.item_name, conditions_to_serialize) .. ")"
end

function UseItem:copy()
    local original = self
    local lookup_table = {}

    local function _copy(original)
        if type(original) ~= "table" then
            return original
        elseif lookup_table[original] then
            return lookup_table[original]
        end
        local new_table = {}
        lookup_table[original] = new_table
        for key, value in pairs(original) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(original))
    end

    return _copy(original)
end

function UseItem:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return UseItem