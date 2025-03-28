local pet_util = require('cylibs/util/pet_util')
local serializer_util = require('cylibs/util/serializer_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')

local ReadyMoveSkillSettings = {}
ReadyMoveSkillSettings.__index = ReadyMoveSkillSettings
ReadyMoveSkillSettings.__type = "ReadyMoveSkillSettings"

-------
-- Default initializer for a new skillchain settings representing a Ready Move.
-- @tparam list blacklist Blacklist of ready move names
-- @treturn ReadyMoveSkillSettings A ready move skill settings
function ReadyMoveSkillSettings.new(blacklist, defaultWeaponSkillName)
    local self = setmetatable({}, ReadyMoveSkillSettings)
    self.all_ready_moves = L(res.job_abilities:with_all('type', 'Monster'))
    self.blacklist = blacklist
    self.defaultWeaponSkillName = defaultWeaponSkillName
    self.defaultWeaponSkillId = job_util.job_ability_id(defaultWeaponSkillName)
    return self
end

-------
-- Returns whether this settings applies to the given player.
-- @tparam Player player The Player
-- @treturn boolean True if the settings is applicable to the player, false otherwise
function ReadyMoveSkillSettings:is_valid(player)
    return player:get_pet() ~= nil
end

-------
-- Returns the list of skillchain abilities included in this settings. Omits abilities on the blacklist but does
-- not check conditions for whether an ability can be performed.
-- @treturn list A list of SkillchainAbility
function ReadyMoveSkillSettings:get_abilities()
    local ready_moves = self.all_ready_moves:filter(
            function(ready_move)
                return not self.blacklist:contains(ready_move.en) and job_util.knows_job_ability(ready_move.id)
            end):map(
            function(ready_move)
                return self:get_ability(ready_move.en)
            end):compact_map():reverse()
    return ready_moves
end

function ReadyMoveSkillSettings:get_ability(ability_name)
    return ReadyMove.new(ability_name, self:get_default_conditions(ability_name))
end

function ReadyMoveSkillSettings:get_default_ability()
    if self.defaultWeaponSkillId and self.defaultWeaponSkillName then
        local ability = SkillchainAbility.new('job_abilities', self.defaultWeaponSkillId, self:get_default_conditions(self.defaultWeaponSkillName))
        if ability then
            return ability
        end
    end
    return nil
end

function ReadyMoveSkillSettings:get_default_conditions(ability_name)
    return L{ ReadyChargesCondition.new(self:get_charges(ability_name), Condition.Operator.GreaterThanOrEqualTo) }:map(function(condition)
        condition:set_editable(false)
        return condition
    end)
end

function ReadyMoveSkillSettings:get_charges(readyMoveName)
    local jobAbility = res.job_abilities:with('en', readyMoveName)
    if jobAbility then
        return jobAbility.mp_cost
    end
    return 3
end

function ReadyMoveSkillSettings:set_default_ability(ability_name)
    local ability = self:get_ability(ability_name)
    if ability then
        self.defaultWeaponSkillId = ability:get_ability_id()
        self.defaultWeaponSkillName = ability:get_name()
    else
        self.defaultWeaponSkillId = nil
        self.defaultWeaponSkillName = nil
    end
end

function ReadyMoveSkillSettings:get_id()
    return nil
end

function ReadyMoveSkillSettings:get_name()
    return 'Ready Moves'
end

function ReadyMoveSkillSettings:serialize()
    return "ReadyMoveSkillSettings.new(" .. serializer_util.serialize_args(self.blacklist, self.defaultWeaponSkillName or '') .. ")"
end

return ReadyMoveSkillSettings