---------------------------
-- Condition checking whether a target begins casting a spell.
-- @class module
-- @name ActionCondition
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ActionCondition = setmetatable({}, { __index = Condition })
ActionCondition.__index = ActionCondition
ActionCondition.__class = "ActionCondition"
ActionCondition.__type = "ActionCondition"

local categories = T{
    --[1] = 'Melee attack', -- too spammy
    [2] = 'Ranged attack finish',
    [3] = 'Weapon Skill finish',
    [4] = 'Casting finish',
    [5] = 'Item finish',
    [6] = 'Job Ability',
    [7] = 'Weapon Skill start',
    [8] = 'Casting start',
    [9] = 'Item start',
    --[11] = 'NPC TP finish',
    [12] = 'Ranged attack start',
    --[13] = 'Avatar TP finish',
    --[14] = 'Job Ability DNC',
    --[15] = 'Job Ability RUN',
}

function ActionCondition.new(category_name)
    local self = setmetatable(Condition.new(), ActionCondition)
    self.category_name = category_name or categories[7]
    return self
end

function ActionCondition:is_satisfied(target_index, action)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and action then
        return categories[action.category] and categories[action.category] == self.category_name
    end
    return false
end

function ActionCondition:get_config_items()
    local all_category_names = L{}
    for _, category_name in pairs(categories) do
        all_category_names:append(category_name)
    end
    return L{
        PickerConfigItem.new('category_name', self.category_name, all_category_names, function(category_name)
            return category_name
        end, "Action Category") }
end

function ActionCondition:tostring()
    return self.category_name
end

function ActionCondition.description()
    return "Performs an action."
end

function ActionCondition.valid_targets()
    return S{ Condition.TargetType.Ally, Condition.TargetType.Enemy }
end

function ActionCondition:serialize()
    return "ActionCondition.new(" .. serializer_util.serialize_args(self.category_name) .. ")"
end

function ActionCondition:__eq(otherItem)
    return otherItem.__class == ActionCondition.__class
            and self.category_name == otherItem.category_name
end

return ActionCondition