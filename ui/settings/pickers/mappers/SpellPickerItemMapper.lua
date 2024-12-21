local Buff = require('cylibs/battle/spells/buff')
local Spell = require('cylibs/battle/spell')

local PickerItemMapper = require('ui/settings/pickers/mappers/PickerItemMapper')
local SpellPickerItemMapper = setmetatable({}, {__index = PickerItemMapper })
SpellPickerItemMapper.__index = SpellPickerItemMapper

function SpellPickerItemMapper.new(defaultJobNames)
    local self = setmetatable(PickerItemMapper.new(), SpellPickerItemMapper)

    self.defaultJobNames = defaultJobNames
    self.selfBuffsWhitelist = S{
        'Absorb-ACC', 'Absorb-STR', 'Absorb-DEX',
        'Absorb-INT', 'Absorb-CHR', 'Absorb-AGI',
        'Absorb-MND', 'Absorb-VIT',
        'Drain II', 'Drain III'
    }
    self.doNotConvertSpellIds = L{
        100, 101, 102, 103, 104, 105, 106, 107, 312, 313, 314, 315, 316, 317, 338, 339, 340,
        857, 858, 859, 860, 861, 862, 863, 864 -- Storms
    }

    return self
end

---
-- Returns whether this mapper can map a given value.
--
-- @tparam any value The value.
-- @treturn boolean True if this mapper can map a value.
--
function SpellPickerItemMapper:canMap(value)
    return S{ Buff.__type, Spell.__type }:contains(value.__type)
end

---
-- Gets the mapped value.
--
-- @tparam any value The value.
-- @treturn table The mapped value.
--
function SpellPickerItemMapper:map(value)
    local spell = value:get_spell()
    local status = buff_util.buff_for_spell(spell.id)
    if status and not L{ 40, 41, 42, 43 }:contains(spell.skill) and not self.doNotConvertSpellIds:contains(spell.id) then
        if S(spell.targets):contains('Enemy') then
            if not self.selfBuffsWhitelist:contains(spell.en) then
                return Debuff.new(spell_util.base_spell_name(value:get_name()), L{}, L{})
            else
                return Spell.new(value:get_name(), L{}, L{}, 'bt')
            end
        else
            return Buff.new(spell_util.base_spell_name(value:get_name()), L{}, self.defaultJobNames)
        end
    else
        return Spell.new(value:get_name(), L{}, L{})
    end
end

return SpellPickerItemMapper