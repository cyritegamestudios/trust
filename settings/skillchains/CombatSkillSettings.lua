
local serializer_util = require('cylibs/util/serializer_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')

local CombatSkillSettings = {}
CombatSkillSettings.__index = CombatSkillSettings
CombatSkillSettings.__type = "CombatSkillSettings"


function CombatSkillSettings.new(combatSkillName, blacklist)
    local self = setmetatable({}, CombatSkillSettings)
    self.combatSkillName = combatSkillName
    self.combatSkillId = res.skills:with('en', self.combatSkillName).id
    self.blacklist = blacklist
    return self
end

function CombatSkillSettings:is_valid(player)
    local weapons = require('cylibs/res/weapons')

    local weapon_ids = L{ player:get_main_weapon_id(), player:get_ranged_weapon_id() }:compact_map()
    for weapon_id in weapon_ids:it() do
        local main_weapon_skill = weapons[weapon_id].skill
        if self.combatSkillId == main_weapon_skill then
            return true
        end
    end
    weapons = nil
    return false
end

function CombatSkillSettings:get_abilities(include_blacklist)
    local weapon_skills = L(windower.ffxi.get_abilities().weapon_skills):filter(function(weapon_skill_id)
        local weapon_skill = res.weapon_skills[weapon_skill_id]
        if weapon_skill.skill == self.combatSkillId then
            return include_blacklist or not self.blacklist:contains(weapon_skill.en)
        end
        return false
    end):map(function(weapon_skill_id)
        return SkillchainAbility.new('weapon_skills', weapon_skill_id, L{ MinTacticalPointsCondition.new(1000) })
    end)
    return weapon_skills
end

function CombatSkillSettings:get_ability(ability_name)
    return WeaponSkill.new(ability_name)
end

function CombatSkillSettings:get_default_ability()
    local highest_weapon_skill_id = L(windower.ffxi.get_abilities().weapon_skills):filter(
            function(weapon_skill_id)
                local weapon_skill = res.weapon_skills[weapon_skill_id]
                return not self.blacklist:contains(weapon_skill.en)
            end):last()
    if highest_weapon_skill_id then
        return SkillchainAbility.new('weapon_skills', highest_weapon_skill_id, L{ MinTacticalPointsCondition.new(1000) })
    end
    return nil
end

function CombatSkillSettings:get_name()
    return self.combatSkillName
end

function CombatSkillSettings:serialize()
    return "CombatSkillSettings.new(" .. serializer_util.serialize_args(self.combatSkillName, self.blacklist) .. ")"
end

return CombatSkillSettings