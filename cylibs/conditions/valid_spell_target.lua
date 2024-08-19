---------------------------
-- Condition checking whether the target is valid target for a spell.
-- @class module
-- @name ValidSpellTargetCondition

local monster_util = require('cylibs/util/monster_util')
local serializer_util = require('cylibs/util/serializer_util')
local spell_util = require('cylibs/util/spell_util')

local ValidTargetCondition = require('cylibs/conditions/valid_target')
local ValidSpellTargetCondition = setmetatable({}, { __index = ValidTargetCondition })
ValidSpellTargetCondition.__index = ValidSpellTargetCondition
ValidSpellTargetCondition.__class = "ValidSpellTargetCondition"

function ValidSpellTargetCondition.new(spell_name, blacklist_names)
    local self = setmetatable(ValidTargetCondition.new(blacklist_names), ValidSpellTargetCondition)
    self.spell_name = spell_name
    return self
end

function ValidSpellTargetCondition:is_satisfied(target_index)
    if not ValidTargetCondition.is_satisfied(self, target_index) then
        return false
    end
    local target_type = self:get_target_type(target_index)
    if target_type == 'Enemy' then
        local target = windower.ffxi.get_mob_by_index(target_index)
        if target and target.hpp <= 0 then
            return false
        end
    end
    local spell_targets = spell_util.spell_targets(self.spell_name)
    return spell_targets:contains(target_type)
end

function ValidSpellTargetCondition:get_target_type(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if res.statuses[target.status].en == 'Dead' then
        return 'Corpse'
    elseif target_index == windower.ffxi.get_player().index then
        return 'Self'
    elseif target.in_party then
        return 'Party'
    elseif target.in_alliance then
        return 'Ally'
    elseif monster_util.is_monster(monster_util.id_for_index(target_index)) then
        return 'Enemy'
    end
    return 'Unknown'
end

function ValidSpellTargetCondition:tostring()
    return "ValidSpellTargetCondition"
end

function ValidSpellTargetCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function ValidSpellTargetCondition:serialize()
    return "ValidSpellTargetCondition.new(" .. serializer_util.serialize_args(self.spell_name, self.blacklist_names) .. ")"
end

return ValidSpellTargetCondition




