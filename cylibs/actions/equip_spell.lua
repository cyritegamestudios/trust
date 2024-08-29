local Action = require('cylibs/actions/action')
local EquipSpellAction = setmetatable({}, {__index = Action })
EquipSpellAction.__index = EquipSpellAction

function EquipSpellAction.new(spell_id, slot_index)
    local conditions = L{
        MainJobCondition.new('BLU'),
    }

    local self = setmetatable(Action.new(0, 0, 0, windower.ffxi.get_player().index, conditions), EquipSpellAction)

    self.spell_id = spell_id
    self.slot_index = slot_index

    return self
end

function EquipSpellAction:perform()
    if self.slot_index then
        windower.ffxi.set_blue_magic_spell(self.spell_id, self.slot_index)
    else
        windower.ffxi.set_blue_magic_spell(self.spell_id)
    end

    coroutine.sleep(0.5)

    self:complete(true)
end

function EquipSpellAction:get_target()
    return windower.ffxi.get_mob_by_index(self.target_index)
end

function EquipSpellAction:gettype()
    return "equipspellaction"
end

function EquipSpellAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self.spell_id == action.spell_id
        and self.slot_index == action.slot_index
end

function EquipSpellAction:tostring()
    return ""
end

function EquipSpellAction:debug_string()
    return "EquipSpellAction: %d %d":format(self.spell_id, self.slot_index)
end

return EquipSpellAction



