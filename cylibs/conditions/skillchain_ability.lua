---------------------------
-- Condition checking whether the current skillchain step matches an ability.
-- @class module
-- @name SkillchainStepCondition
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local skills = require('cylibs/res/skills')

local Condition = require('cylibs/conditions/condition')
local SkillchainAbilityCondition = setmetatable({}, { __index = Condition })
SkillchainAbilityCondition.__index = SkillchainAbilityCondition
SkillchainAbilityCondition.__class = "SkillchainAbilityCondition"
SkillchainAbilityCondition.__type = "SkillchainAbilityCondition"

function SkillchainAbilityCondition.new(ability_name)
    local self = setmetatable(Condition.new(), SkillchainAbilityCondition)
    self.ability_name = ability_name or 'Combo'
    return self
end

function SkillchainAbilityCondition:is_satisfied(target_index)
    local skillchainer = player.trust.main_job:role_with_type("skillchainer")
    local party = player.party
    local player = player.party:get_player()
    if player then
        local enemy = party:get_target_by_index(player:get_target_index())
        if enemy then
            local current_step = skillchainer.skillchain_tracker:get_current_step(enemy:get_id())
            if current_step then
                return current_step:get_ability() and current_step:get_ability():get_name() == self.ability_name
            end
        end
    end
    return false
end

function SkillchainAbilityCondition:get_config_items()
    local all_abilities = L{}
    for _, ability_category in pairs(skills) do
        for _, ability in pairs(ability_category) do
            all_abilities:append(ability.en)
        end
    end
    all_abilities = all_abilities:compact_map():unique()
    all_abilities:sort()
    return L{
        PickerConfigItem.new('ability_name', self.ability_name or all_abilities[1], all_abilities, nil, "Ability Name")
    }
end

function SkillchainAbilityCondition:tostring()
    return string.format("Last skillchain ability was %s", self.ability_name)
end

function SkillchainAbilityCondition.description()
    return "Last skillchain ability."
end

function SkillchainAbilityCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy }
end

function SkillchainAbilityCondition:serialize()
    return "SkillchainAbilityCondition.new(" .. serializer_util.serialize_args(self.ability_name) .. ")"
end

function SkillchainAbilityCondition:__eq(otherItem)
    return otherItem.__class == SkillchainAbilityCondition.__class
            and self.ability_name == otherItem.ability_name
end

return SkillchainAbilityCondition