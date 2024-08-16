---------------------------
-- Condition checking whether the target has any of the given combat skills.
-- @class module
-- @name CombatSkillsCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local CombatSkillsCondition = setmetatable({}, { __index = Condition })
CombatSkillsCondition.__index = CombatSkillsCondition
CombatSkillsCondition.__type = "CombatSkillsCondition"
CombatSkillsCondition.__class = "CombatSkillsCondition"

function CombatSkillsCondition.new(combat_skill_names)
    local self = setmetatable(Condition.new(), CombatSkillsCondition)
    self.combat_skill_names = combat_skill_names or L{}
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

function CombatSkillsCondition:tostring()
    return "Combat skills are "..localization_util.commas(self.combat_skill_names, 'or')
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




