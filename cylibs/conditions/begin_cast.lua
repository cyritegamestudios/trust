---------------------------
-- Condition checking whether a target begins casting a spell.
-- @class module
-- @name BeginCastCondition
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local BeginCastCondition = setmetatable({}, { __index = Condition })
BeginCastCondition.__index = BeginCastCondition
BeginCastCondition.__class = "BeginCastCondition"
BeginCastCondition.__type = "BeginCastCondition"

function BeginCastCondition.new(spell_name)
    local self = setmetatable(Condition.new(), BeginCastCondition)
    self.spell_name = spell_name or 'Stone'
    return self
end

function BeginCastCondition:is_satisfied(target_index, spell_name)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self.spell_name == spell_name
    end
    return false
end

function BeginCastCondition:get_config_items()
    local all_spell_names = L{}

    local spell_types = L{ 'BlackMagic', 'WhiteMagic' }
    for type in spell_types:it() do
        all_spell_names = all_spell_names + res.spells:with_all('type', type):map(function(spell)
            return spell.en
        end)
    end
    all_spell_names = L(S(all_spell_names))
    all_spell_names:sort()
    return L{
        PickerConfigItem.new('spell_name', self.spell_name, all_spell_names, function(spell_name)
            return Spell.new(spell_name):get_localized_name()
        end, "Spell") }
end

function BeginCastCondition:tostring()
    return "Begins casting "..self.spell_name
end

function BeginCastCondition.description()
    return "Begins casting a spell."
end

function BeginCastCondition.valid_targets()
    return S{ Condition.TargetType.Ally, Condition.TargetType.Enemy }
end

function BeginCastCondition:serialize()
    return "BeginCastCondition.new(" .. serializer_util.serialize_args(self.spell_name) .. ")"
end

function BeginCastCondition:__eq(otherItem)
    return otherItem.__class == BeginCastCondition.__class
            and self.spell_name == otherItem.spell_name
end

return BeginCastCondition