---------------------------
-- Job file for Ninja.
-- @class module
-- @name Ninja

local ConditionalCondition = require('cylibs/conditions/conditional')

local Job = require('cylibs/entity/jobs/job')
local Ninja = setmetatable({}, {__index = Job })
Ninja.__index = Ninja

-------
-- Default initializer for a new Ninja.
-- @treturn NIN A Ninja
function Ninja.new()
    local self = setmetatable(Job.new('NIN'), Ninja)
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Ninja:get_aoe_spells()
    return L{}
end

-------
-- Returns whether the player has any copy images.
-- @tparam list player_buff_ids List of active player buffs
-- @treturn boolean True if the player has at least one copy image remaining
function Ninja:has_shadows(player_buff_ids)
    player_buff_ids = L(windower.ffxi.get_player().buffs)
    return buff_util.is_any_buff_active(L{ 66, 444, 445, 446 }, player_buff_ids)
end

-------
-- Returns whether an Utsusemi spell overrides another Utsusemi spell.
-- @tparam number current_spell_id Spell id of current shadows
-- @tparam number new_spell_id Spell id of new shadows
-- @treturn boolean True if the new spell overrides the current spell
function Ninja:should_cancel_shadows(current_spell_id, new_spell_id)
    if current_spell_id == nil then
        return true
    elseif current_spell_id == 338 then
        return false--L{ 339, 340 }:contains(new_spell_id)
    elseif current_spell_id == 339 then
        return L{ 338 }:contains(new_spell_id)
    elseif current_spell_id == 340 then
        return L{ 338, 339 }:contains(new_spell_id)
    else
        return false
    end
end

-------
-- Returns a list of conditions for an ability.
-- @tparam Spell|JobAbility ability The ability
-- @treturn list List of conditions
function Ninja:get_conditions_for_ability(ability)
    local conditions = ability:get_conditions()
    local tools = self:get_tools_for_spell(ability)
    if tools:length() > 0 then
        local item_conditions = tools:map(function(tool_name)
            return ItemCountCondition.new(tool_name, 1, Condition.Operator.GreaterThanOrEqualTo)
        end)
        conditions:append(ConditionalCondition.new(item_conditions, Condition.LogicalOperator.Or))
    end
    return conditions
end

local Ninjutsu = {}

Ninjutsu.Buffing = L{
    'Tonko', 'Utsusemi', 'Monomi',
    'Myoshu', 'Migawari', 'Gekka', 'Yain',
    'Kakka'
}
Ninjutsu.Enfeebling = L{
    'Kurayami', 'Hojo', 'Dokumori',
    'Jubaku', 'Aisha', 'Yurin',
}
Ninjutsu.Elemental = L{
    'Katon', 'Suiton', 'Raiton',
    'Doton', 'Huton', 'Hyoton',
}

function Ninja:get_tools_for_spell(spell)
    local match = function(list, term)
        for el in list:it() do
            local result = string.match(term, el)
            if result then
                return true
            end
        end
        return false
    end
    if match(Ninjutsu.Buffing, spell:get_name()) then
        return L{'Shikanofuda'}
    elseif match(Ninjutsu.Enfeebling, spell:get_name()) then
        return L{'Chonofuda'}
    elseif match(Ninjutsu.Elemental, spell:get_name()) then
        return L{'Inoshishinofuda'}
    else
        return L{}
    end
end

return Ninja