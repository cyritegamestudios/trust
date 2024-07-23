---------------------------
-- Condition checking the number of resists for a specific debuff.
-- @class module
-- @name NumResistsCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local NumResistsCondition = setmetatable({}, { __index = Condition })
NumResistsCondition.__index = NumResistsCondition
NumResistsCondition.__type = "NumResistsCondition"
NumResistsCondition.__class = "NumResistsCondition"

function NumResistsCondition.new(spell_name, operator, num_resists)
    local self = setmetatable(Condition.new(), NumResistsCondition)
    self.spell_name = spell_name or "Distract"
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    self.num_resists = num_resists or 4
    return self
end

function NumResistsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local monster = player.party:get_target(target.id)
        if monster then
            return Condition:eval(monster:get_resist_tracker():numResists(spell_util.spell_id(self.spell_name)), self.num_resists, self.operator)
        end
    end
    return false
end

function NumResistsCondition:get_config_items()
    local all_spells = S(buff_util.get_all_debuff_spells():compact_map())
    all_spells = L(all_spells)
    all_spells:sort()

    return L{
        PickerConfigItem.new('spell_name', self.spell_name, all_spells, function(spell_name)
            return spell_name:gsub("^%l", string.upper)
        end, "Spell"),
        ConfigItem.new('num_resists', 1, 20, 1, nil, "Number of Resists"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function NumResistsCondition:tostring()
    return self.spell_name.." resisted "..self.operator.." "..self.num_resists.." times"
end

function NumResistsCondition.description()
    return "Number of times spell has been resisted."
end

function NumResistsCondition:serialize()
    return "NumResistsCondition.new(" .. serializer_util.serialize_args(self.spell_name, self.operator, self.num_resists) .. ")"
end

function NumResistsCondition:__eq(otherItem)
    return otherItem.__class == NumResistsCondition.__class
            and otherItem.accuracy_percentage == self.accuracy_percentage
            and otherItem.operator == self.operator
end

return NumResistsCondition




