---------------------------
-- Condition checking whether a target finishes a given ability.
-- @class module
-- @name FinishAbilityCondition
local monster_util = require('cylibs/util/monster_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local FinishAbilityCondition = setmetatable({}, { __index = Condition })
FinishAbilityCondition.__index = FinishAbilityCondition
FinishAbilityCondition.__class = "FinishAbilityCondition"
FinishAbilityCondition.__type = "FinishAbilityCondition"

function FinishAbilityCondition.new(ability_name)
    local self = setmetatable(Condition.new(), FinishAbilityCondition)
    self.ability_name = ability_name or 'Foot Kick'
    return self
end

function FinishAbilityCondition:is_satisfied(target_index, ability_name)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self.ability_name == ability_name
    end
    return false
end

function FinishAbilityCondition:get_config_items()
    local all_ability_names = S(monster_util.get_all_ability_ids():map(function(ability_id)
        local monster_ability = res.monster_abilities[ability_id]
        if monster_ability then
            return monster_ability.en
        end
        return nil
    end):compact_map())
    all_ability_names = L(all_ability_names)
    all_ability_names:sort()
    return L{
        PickerConfigItem.new('ability_name', self.ability_name, all_ability_names, function(ability_name)
            return ability_name:gsub("^%l", string.upper)
        end, "Ability") }
end

function FinishAbilityCondition:tostring()
    return "Finishes "..self.ability_name
end

function FinishAbilityCondition:serialize()
    return "FinishAbilityCondition.new(" .. serializer_util.serialize_args(self.ability_name) .. ")"
end

function FinishAbilityCondition:__eq(otherItem)
    return otherItem.__class == FinishAbilityCondition.__class
            and self.ability_name == otherItem.ability_name
end

return FinishAbilityCondition