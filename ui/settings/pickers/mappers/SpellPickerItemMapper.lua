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
-- Returns whether this PickerItemMapper can map a given picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn boolean True if this mapper can map a picker item.
--
function SpellPickerItemMapper:canMap(pickerItem)
    return res.spells:with('en', pickerItem:getText()) ~= nil
end

---
-- Gets the mapped picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn table The mapped picker item.
--
function SpellPickerItemMapper:map(pickerItem)
    local spell = res.spells:with('en', pickerItem:getText())
    local status = buff_util.buff_for_spell(spell.id)
    if status and not L{ 40, 41, 42, 43 }:contains(spell.skill) and not self.doNotConvertSpellIds:contains(spell.id) then
        if S(spell.targets):contains('Enemy') then
            if not self.selfBuffsWhitelist:contains(spell.en) then
                return Debuff.new(spell_util.base_spell_name(pickerItem:getText()), L{}, L{})
            else
                return Spell.new(pickerItem:getText(), L{}, L{}, 'bt')
            end
        else
            return Buff.new(spell_util.base_spell_name(pickerItem:getText()), L{}, self.defaultJobNames)
        end
    else
        return Spell.new(pickerItem:getText(), L{}, L{})
    end
end

return SpellPickerItemMapper