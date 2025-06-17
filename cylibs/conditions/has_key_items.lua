---------------------------
-- Condition checking whether the player has the specified key items.
-- @class module
-- @name HasKeyItemsCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')

local HasKeyItemsCondition = setmetatable({}, { __index = Condition })
HasKeyItemsCondition.__index = HasKeyItemsCondition
HasKeyItemsCondition.__type = "HasKeyItemsCondition"
HasKeyItemsCondition.__class = "HasKeyItemsCondition"

function HasKeyItemsCondition.new(key_item_names, item_count, operator)
    local self = setmetatable(Condition.new(), HasKeyItemsCondition)
    self.key_item_names = key_item_names or "\"Rhapsody in White\""
    self.item_count = item_count or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function HasKeyItemsCondition:is_satisfied(_)
    local key_items = S(windower.trust.get_inventory():getKeyItems())
    local key_item_count = self.key_item_names:filter(function(key_item_name)
        local key_item = res.key_items:with('en', key_item_name)
        return key_item and key_items:contains(key_item.id)
    end):length()
    return self:eval(key_item_count, self.item_count, self.operator)
end

function HasKeyItemsCondition:get_config_items()
    return L{}
end

function HasKeyItemsCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function HasKeyItemsCondition:serialize()
    return "HasKeyItemsCondition.new(" .. serializer_util.serialize_args(self.key_item_names, self.item_count, self.operator) .. ")"
end

function HasKeyItemsCondition:tostring()
    return "Has"..' '..self.operator..' '..self.item_count..' '..localization_util.commas(self.key_item_names)
end

function HasKeyItemsCondition.description()
    return "Has key items."
end

function HasKeyItemsCondition:__eq(otherItem)
    return otherItem.__class == HasKeyItemsCondition.__class
            and self.key_item_names == otherItem.key_item_names
            and self.item_count == otherItem.item_count
            and self.operator == otherItem.operator
end

return HasKeyItemsCondition




