---------------------------
-- Condition checking whether a target is readying a given ability.
-- @class module
-- @name ReadyAbilityCondition
local monster_util = require('cylibs/util/monster_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ReadyAbilityCondition = setmetatable({}, { __index = Condition })
ReadyAbilityCondition.__index = ReadyAbilityCondition
ReadyAbilityCondition.__class = "ReadyAbilityCondition"
ReadyAbilityCondition.__type = "ReadyAbilityCondition"

function ReadyAbilityCondition.new(ability_name)
    local self = setmetatable(Condition.new(), ReadyAbilityCondition)
    self.ability_name = ability_name or 'Foot Kick'
    return self
end

function ReadyAbilityCondition:is_satisfied(target_index, ability_name)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self.ability_name == ability_name
    end
    return false
end

function ReadyAbilityCondition:get_config_items()
    local all_ability_names = S(monster_util.get_all_ability_ids():map(function(ability_id)
        return res.monster_abilities[ability_id].en
    end))
    all_ability_names = L(all_ability_names)
    all_ability_names:sort()
    return L{
        PickerConfigItem.new('ability_name', self.ability_name, all_ability_names, function(ability_name)
            return ability_name:gsub("^%l", string.upper)
        end, "Ability") }
end

function ReadyAbilityCondition:tostring()
    return "Readies "..self.ability_name
end

function ReadyAbilityCondition:serialize()
    return "ReadyAbilityCondition.new(" .. serializer_util.serialize_args(self.ability_name) .. ")"
end

function ReadyAbilityCondition:__eq(otherItem)
    return otherItem.__class == ReadyAbilityCondition.__class
            and self.ability_name == otherItem.ability_name
end

return ReadyAbilityCondition