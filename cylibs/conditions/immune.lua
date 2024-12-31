---------------------------
-- Condition checking whether the target is immune to a debuff.
-- @class module
-- @name IsImmuneCondition

local buff_util = require('cylibs/util/buff_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local IsImmuneCondition = setmetatable({}, { __index = Condition })
IsImmuneCondition.__index = IsImmuneCondition
IsImmuneCondition.__type = "IsImmuneCondition"
IsImmuneCondition.__class = "IsImmuneCondition"

function IsImmuneCondition.new(spell_name, target_index)
    local self = setmetatable(Condition.new(target_index), IsImmuneCondition)
    self.spell_name = spell_name or "Sleep"
    return self
end

function IsImmuneCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local monster = player.alliance:get_target_by_index(target_index)
        if monster then
            return monster:get_resist_tracker():isImmune(spell_util.spell_id(self.spell_name))
        end
    end
    return false
end

function IsImmuneCondition:get_config_items()
    local all_spells = L(player.trust.main_job:get_job():get_spells(function(spellId)
        local spell = res.spells[spellId]
        if spell then
            local status = buff_util.buff_for_spell(spell.id)
            return status ~= nil and buff_util.is_debuff(status.id) and S{ 32, 35, 36, 37, 39, 40, 41, 42 }:contains(spell.skill) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0
        end
        return false
    end):map(function(spellId)
        return Spell.new(res.spells[spellId].en)
    end))
    return L{
        PickerConfigItem.new('spell_name', self.spell_name, all_spells, function(spell)
            return spell:get_localized_name()
        end, "Spell Name")
    }
end

function IsImmuneCondition:tostring()
    return "Is immune to "..i18n.resource('spells', 'en', self.spell_name)
end

function IsImmuneCondition.description()
    return "Is immune to spell."
end

function IsImmuneCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

--function IsImmuneCondition:serialize()
--    return "IsImmuneCondition.new(" .. serializer_util.serialize_args(self.spell_name) .. ")"
--end

function IsImmuneCondition:__eq(otherItem)
    return otherItem.__class == IsImmuneCondition.__class
            and otherItem.spell_name == self.spell_name
end

return IsImmuneCondition




