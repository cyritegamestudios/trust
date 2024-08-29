---------------------------
-- Condition checking whether the given skillchain is in the list of allowed skillchain properties (e.g. Fusion, Light)
-- @class module
-- @name SkillchainPropertyCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local localization_util = require('cylibs/util/localization_util')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local skillchain_util = require('cylibs/util/skillchain_util')

local Condition = require('cylibs/conditions/condition')
local SkillchainPropertyCondition = setmetatable({}, { __index = Condition })
SkillchainPropertyCondition.__index = SkillchainPropertyCondition
SkillchainPropertyCondition.__class = "SkillchainPropertyCondition"
SkillchainPropertyCondition.__type = "SkillchainPropertyCondition"

function SkillchainPropertyCondition.new(allowed_skillchain_properties)
    local self = setmetatable(Condition.new(), SkillchainPropertyCondition)
    self.allowed_skillchain_properties = L((allowed_skillchain_properties or L{ skillchain_util.Light }):map(function(skillchain)
        if type(skillchain) == 'string' then
            return skillchain
        else
            return skillchain:get_name()
        end
    end))
    return self
end

function SkillchainPropertyCondition:is_satisfied(target_index, skillchain)
    if skillchain then
        if type(skillchain) ~= 'string' then
            skillchain = skillchain:get_name()
        end
        if S(self.allowed_skillchain_properties):contains(skillchain) then
            return true
        end
    end
    return false
end

function SkillchainPropertyCondition:get_config_items()
    local all_skillchain_properties = L(skillchain_util.AllSkillchains):map(function(skillchain) return skillchain:get_name() end)
    all_skillchain_properties:append('None')
    all_skillchain_properties:sort()

    local textFormat = function(skillchain)
        if type(skillchain) == 'string' then
            return skillchain
        end
        return skillchain:get_name()
    end

    return L{
        MultiPickerConfigItem.new('allowed_skillchain_properties', self.allowed_skillchain_properties, all_skillchain_properties, nil, "Skillchain Properties")
    }
end

function SkillchainPropertyCondition:tostring()
    return "Skillchain property is "..localization_util.commas(self.allowed_skillchain_properties or L{}, 'or')
end

function SkillchainPropertyCondition.description()
    return "Active skillchain property."
end

function SkillchainPropertyCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function SkillchainPropertyCondition:serialize()
    return "SkillchainPropertyCondition.new(" .. serializer_util.serialize_args(self.allowed_skillchain_properties) .. ")"
end

function SkillchainPropertyCondition:__eq(otherItem)
    return otherItem.__class == SkillchainPropertyCondition.__class
            and self.allowed_skillchain_properties == otherItem.allowed_skillchain_properties
end

return SkillchainPropertyCondition