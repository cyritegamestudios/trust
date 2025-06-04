local skills = require('cylibs/res/skills')
local serializer_util = require('cylibs/util/serializer_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')

local BloodPactSkillSettings = {}
BloodPactSkillSettings.__index = BloodPactSkillSettings
BloodPactSkillSettings.__type = "BloodPactSkillSettings"

-------
-- Default initializer for a new skillchain settings representing a Blood Pact: Rage.
-- @tparam list blacklist Blacklist of blood pact names
-- @treturn BloodPactSkillSettings A blood pact skill settings
function BloodPactSkillSettings.new(blacklist, defaultWeaponSkillName)
    local self = setmetatable({}, BloodPactSkillSettings)
    self.all_blood_pacts = L(res.job_abilities:with_all('type', 'BloodPactRage'))
    self.blacklist = blacklist
    self.defaultWeaponSkillName = defaultWeaponSkillName
    self.defaultWeaponSkillId = job_util.job_ability_id(defaultWeaponSkillName)
    return self
end

-------
-- Returns whether this settings applies to the given player.
-- @tparam Player player The Player
-- @treturn boolean True if the settings is applicable to the player, false otherwise
function BloodPactSkillSettings:is_valid(player)
    return player:get_pet() ~= nil
end

-------
-- Returns the list of skillchain abilities included in this settings. Omits abilities on the blacklist but does
-- not check conditions for whether an ability can be performed.
-- @treturn list A list of SkillchainAbility
function BloodPactSkillSettings:get_abilities(include_blacklist, include_unknown)
    local blood_pacts = self.all_blood_pacts:filter(
            function(blood_pact)
                if self.blacklist:contains(blood_pact.en) and not include_blacklist then
                    return false
                end
                return (job_util.knows_job_ability(blood_pact.id) or include_unknown) and skills.job_abilities[blood_pact.id] ~= nil
            end):map(
            function(blood_pact)
                return self:get_ability(blood_pact.en)
            end):reverse()
    return blood_pacts
end

function BloodPactSkillSettings:get_ability(ability_name)
    return BloodPactRage.new(ability_name, self:get_default_conditions(ability_name))
end

function BloodPactSkillSettings:get_default_ability()
    if self.defaultWeaponSkillName then
        return self:get_ability(self.defaultWeaponSkillName)
    end
    return nil
end

function BloodPactSkillSettings:get_default_conditions(ability_name)
    return L{ JobAbilityRecastReadyCondition.new(ability_name) }:map(function(condition)
        condition:set_editable(false)
        return condition
    end)
end

function BloodPactSkillSettings:set_default_ability(ability_name)
    local ability = self:get_ability(ability_name)
    if ability then
        self.defaultWeaponSkillId = ability:get_ability_id()
        self.defaultWeaponSkillName = ability:get_name()
    else
        self.defaultWeaponSkillId = nil
        self.defaultWeaponSkillName = nil
    end
end

function BloodPactSkillSettings:get_id()
    return nil
end

function BloodPactSkillSettings:get_name()
    return 'Blood Pacts'
end

function BloodPactSkillSettings:serialize()
    return "BloodPactSkillSettings.new(" .. serializer_util.serialize_args(self.blacklist, self.defaultWeaponSkillName or '') .. ")"
end

return BloodPactSkillSettings