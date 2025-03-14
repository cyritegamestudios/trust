---------------------------
-- Condition checking the count of an item in the player's inventory.
-- @class module
-- @name ItemCountCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local Item = require('resources/resources').Item
local inventory_util = require('cylibs/util/inventory_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local ItemCountCondition = setmetatable({}, { __index = Condition })
ItemCountCondition.__index = ItemCountCondition
ItemCountCondition.__type = "ItemCountCondition"
ItemCountCondition.__class = "ItemCountCondition"

function ItemCountCondition.new(item_name, item_count, operator)
    local self = setmetatable(Condition.new(), ItemCountCondition)
    self.item_name = item_name or "Grape Daifuku"
    self.item_count = item_count or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function ItemCountCondition:is_satisfied(_)
    return self:eval(inventory_util.get_item_count(self.item_name), self.item_count, self.operator)
end

function ItemCountCondition:get_config_items()
    local item_names = L(Item:where("category == 'Usable' OR stack > 1", L{ "en" }, true)):map(function(item) return item.en end):unique():sort()
    return L{
        PickerConfigItem.new('item_name', self.item_name, item_names, nil, "Item Name"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator"),
        ConfigItem.new('item_count', 0, 99, 1, function(value) return value.."" end, "Number of Item"),
    }
end

function ItemCountCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function ItemCountCondition:serialize()
    return "ItemCountCondition.new(" .. serializer_util.serialize_args(self.item_name, self.item_count, self.operator) .. ")"
end

function ItemCountCondition:tostring()
    return "Has"..' '..self.operator..' '..self.item_count..' '..self.item_name
end

function ItemCountCondition.description()
    return "Has item in inventory."
end

function ItemCountCondition:__eq(otherItem)
    return otherItem.__class == ItemCountCondition.__class
            and self.item_name == otherItem.item_name
            and self.item_count == otherItem.item_count
            and self.operator == otherItem.operator
end

return ItemCountCondition




