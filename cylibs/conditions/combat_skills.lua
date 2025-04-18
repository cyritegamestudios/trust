---------------------------
-- Condition checking whether the target has any of the given combat skills.
-- @class module
-- @name CombatSkillsCondition
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local CombatSkillsCondition = setmetatable({}, { __index = Condition })
CombatSkillsCondition.__index = CombatSkillsCondition
CombatSkillsCondition.__type = "CombatSkillsCondition"
CombatSkillsCondition.__class = "CombatSkillsCondition"

function CombatSkillsCondition.new(combat_skill_names)
    local self = setmetatable(Condition.new(), CombatSkillsCondition)
    self.combat_skill_names = combat_skill_names or L{ 'Dagger' }
    return self
end

function CombatSkillsCondition:is_satisfied(_)
    local target = player.party:get_player()
    if target then
        local current_combat_skill_names = target:get_combat_skill_ids():map(function(combat_skill_id)
            return res.skills[combat_skill_id].en
        end)
        for combat_skill_name in self.combat_skill_names:it() do
            if current_combat_skill_names:contains(combat_skill_name) then
                return true
            end
        end
    end
    return false
end

function CombatSkillsCondition:get_config_items()
    local all_combat_skills = L{
        'Hand-to-Hand',
        'Dagger',
        'Sword',
        'Great Sword',
        'Axe',
        'Great Axe',
        'Scythe',
        'Polearm',
        'Katana',
        'Great Katana',
        'Club',
        'Staff',
        'Archery',
        'Marksmanship',
        'Throwing'
    }
    local combatSkillsConfigItem = MultiPickerConfigItem.new('combat_skill_names', self.combat_skill_names, all_combat_skills, function(combat_skills)
        return localization_util.commas(combat_skills:map(function(combat_skill) return i18n.resource('skills', 'en', combat_skill) end), 'or')
    end, "Combat Skills")
    combatSkillsConfigItem:setPickerTitle("Skills")
    combatSkillsConfigItem:setPickerDescription("Choose one or more combat skills.")
    combatSkillsConfigItem:setPickerTextFormat(function(combat_skill)
        return i18n.resource('skills', 'en', combat_skill)
    end)
    return L{
        combatSkillsConfigItem
    }
end

function CombatSkillsCondition:tostring()
    if self.combat_skill_names:length() == 1 then
        return string.format("Combat skill is %s", i18n.resource('skills', 'en', self.combat_skill_names[1]))
    end
    return "Combat skills are "..localization_util.commas(self.combat_skill_names:map(function(combat_skill_name)
        return i18n.resource('skills', 'en', combat_skill_name)
    end), 'or')
end

function CombatSkillsCondition.description()
    return "Has combat skills."
end

function CombatSkillsCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function CombatSkillsCondition:serialize()
    return "CombatSkillsCondition.new(" .. serializer_util.serialize_args(self.combat_skill_names) .. ")"
end

function CombatSkillsCondition:__eq(otherItem)
    return otherItem.__class == CombatSkillsCondition.__class
            and otherItem.combat_skill_names == self.combat_skill_names
end

return CombatSkillsCondition




