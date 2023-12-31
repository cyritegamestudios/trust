local HasBuffsCondition = require('cylibs/conditions/has_buffs')
local res = require('resources')
local skillchain_util = require('cylibs/util/skillchain_util')
local skills = require('cylibs/res/skills')

local SkillchainAbility = {}
SkillchainAbility.__index = SkillchainAbility
SkillchainAbility.__class = "SkillchainAbility"

-------
-- Default initializer for a SkillchainAbility that represents any ability (or spell) that can participate in a skillchain.
-- @tparam string resource Resource for the ability (e.g. `weapon_skills` for `res/weapon_skills.lua`)
-- @tparam number ability_id Id of the ability within the resource file
-- @tparam PartyMember party_member Party member that used the ability
-- @treturn SkillchainAbility A skillchain abilty
function SkillchainAbility.new(resource, ability_id, party_member)
    local self = setmetatable({
        resource = resource;
        ability_id = ability_id;
        party_member = party_member;
    }, SkillchainAbility)
    return self
end

function SkillchainAbility:destroy()
end

-------
-- Returns the name of the ability.
-- @treturn string Name of ability (e.g. `Fire VI`, `Catastrophe`)
function SkillchainAbility:get_name()
    return res[self.resource][self.ability_id].name
end

-- Returns the buffs required to skillchain with this ability (e.g. `Immanence`)
-- @treturn number Buff id (see res/buffs.lua)
function SkillchainAbility:get_buffs()
    local skill = skills[self.resource][self.ability_id]
    if skill and skill.buffs then
        return S(skill.buffs)
    end
    return S{}
end

-- Returns the list of conditions that must be met to skillchain with this ability.
-- @treturn list List of conditions
function SkillchainAbility:get_conditions()
    local buffs = self:get_buffs()
    if buffs:length() > 0 then
        return L{ HasBuffsCondition.from_party_member( buffs:map(function(buff_id) return buff_util.buff_name(buff_id) end), false, self.party_member) }
    end
    return L{}
end

-- Returns the amount of time this ability extends the skillchain window by.
-- @treturn number Delay in seconds
function SkillchainAbility:get_delay()
    local skill = skills[self.resource][self.ability_id]
    if skill then
        return skill.delay or 3
    end
    return 3
end

-- Returns the skillchain properties of this ability (e.g. `Light`, `Fire`, `Water`).
-- @treturn list List of skillchain properties (see util/skillchain_util.lua)
function SkillchainAbility:get_skillchain_properties()
    local skill = skills[self.resource][self.ability_id]
    return L(skill.skillchain):map(function(property_name) return skillchain_util[property_name] end)
end

return SkillchainAbility