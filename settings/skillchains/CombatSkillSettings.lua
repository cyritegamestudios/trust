local serializer_util = require('cylibs/util/serializer_util')

require('logger')

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

function CombatSkillSettings:get_skill_id()
    return self.combatSkillId
end

function CombatSkillSettings:get_weapon_skills()
    local weapon_skills = L(windower.ffxi.get_abilities().weapon_skills):filter(function(weapon_skill_id)
        local weapon_skill = res.weapon_skills[weapon_skill_id]
        if weapon_skill.skill == self.combatSkillId then
            return not self.blacklist:contains(weapon_skill.en)
        end
        return false
    end):map(function(weapon_skill_id)
        return WeaponSkill.new(res.weapon_skills[weapon_skill_id].en)
    end)
    return weapon_skills
end

function CombatSkillSettings:serialize()
    return "CombatSkillSettings.new(" .. serializer_util.serialize_args(self.combatSkillName, self.blacklist) .. ")"
end

return CombatSkillSettings