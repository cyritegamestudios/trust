---------------------------
-- Wrapper around a debuff spell.
-- @class module
-- @name Debuff

local serializer_util = require('cylibs/util/serializer_util')

local Spell = require('cylibs/battle/spell')
local Debuff = setmetatable({}, {__index = Spell })
Debuff.__index = Debuff
Debuff.__type = "Debuff"

-------
-- Default initializer for a new debuff spell.
-- @tparam number buff_id Debuff id (see buffs.lua)
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string spell_prefix string Prefix for spell name (optional) (see spells.lua)
-- @treturn Spell A spell
function Debuff.new(spell_name, job_abilities, job_names, conditions)
    local spell = res.spells:with('en', spell_name)
    spell = spell_util.highest_spell_for_buff_id(spell_util.buff_id_for_spell(spell.id), spell_name) or spell
    if spell then
        local self = setmetatable(Spell.new(spell.en, job_abilities or L{}, job_names, nil, conditions), Debuff)
        self.original_spell_name = spell_name
        return self
    else
        return nil
    end
end

function Debuff:get_localized_name()
    return i18n.resource('spells', 'en', self:get_name())
end

function Debuff:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Debuff.new(" .. serializer_util.serialize_args(self.original_spell_name, self.job_abilities, L{}, conditions_to_serialize) .. ")"
end

function Debuff:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name()
            and otherItem.original_spell_name == self.original_spell_name then
        return true
    end
    return false
end

return Debuff