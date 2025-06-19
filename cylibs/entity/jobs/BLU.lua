---------------------------
-- Job file for Blue Mage.
-- @class module
-- @name BlueMage

local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local EquipSpellAction = require('cylibs/actions/equip_spell')
local StatusRemoval = require('cylibs/battle/healing/status_removal')

local Job = require('cylibs/entity/jobs/job')
local BlueMage = setmetatable({}, {__index = Job })
BlueMage.__index = BlueMage

-------
-- Default initializer for a new Blue Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn BLU A Blue Mage
function BlueMage.new()
    local self = setmetatable(Job.new('BLU'), BlueMage)

    self.spells_action_queue = ActionQueue.new(nil, true, 20, false, false)
    self.dispose_bag = DisposeBag.new()

    self.dispose_bag:addAny(L{ self.spells_action_queue })

    return self
end

-------
-- Returns a list of known spell ids.
-- @tparam function filter Optional filter function
-- @treturn list List of known spell ids
function BlueMage:get_spells(filter)
    filter = filter or function(_) return true end

    return self.spell_list:getKnownSpellIds():filter(function(spell_id)
        local spell = res.spells[spell_id]
        if spell.blu_points then
            local equipped_spell_ids = self:get_equipped_spells()
            if not equipped_spell_ids:contains(spell.id) then
                return false
            end
        end
        return filter(spell_id)
    end)
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function BlueMage:get_aoe_spells()
    return L{
        'Searing Tempest', 'Blinding Fulgor', 'Spectral Floe', 'Scouring Spate',
        'Anvil Lightning', 'Silent Storm', 'Entomb', 'Tenebral Crush',
    }
end

-------
-- Returns a list of conditions for a spell.
-- @tparam Spell spell The spell
-- @treturn list List of conditions
function BlueMage:get_conditions_for_spell(spell)
    local magicalSpells = S(self:get_spells(function(spell_id)
        local spell = res.spells[spell_id]
        return spell and S{ 'BlueMagic' }:contains(spell.type) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0 and spell.element ~= 15
    end):map(function(spell_id)
        return res.spells[spell_id].en
    end))
    if magicalSpells:contains(spell:get_spell().en) then
        return spell:get_conditions() + L{JobAbilityRecastReadyCondition.new('Burst Affinity')}
    end
    return spell:get_conditions()
end

-------
-- Returns a set of equipped spell ids.
-- @treturn set Set of equipped spell ids
function BlueMage:get_equipped_spells()
    local equipped_spell_ids = L{}

    local spell_list = L{ windower.ffxi.get_mjob_data().spells, windower.ffxi.get_sjob_data().spells }:compact_map()
    for spell_ids in spell_list:it() do
        for _, spell_id in pairs(spell_ids) do
            if spell_id then
                equipped_spell_ids:append(spell_id)
            end
        end
    end
    return S(equipped_spell_ids)
end

-------
-- Returns whether a given spell is currently equipped.
-- @tparam string spell_name Spell name (see res/spells.lua)
-- @treturn boolean True if the spell is equipped, false otherwise
function BlueMage:has_spell_equipped(spell_name)
    local spells = windower.ffxi.get_mjob_data().spells
    for _, spell_id in pairs(spells) do
        if spell_id == spell_util.spell_id(spell_name) then
            return true
        end
    end
    return false
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function BlueMage:get_raise_spell()
    return nil
end

function BlueMage:create_spell_set()
    local equipped_spells = L(self:get_equipped_spells())
    if equipped_spells:length() == 0 then
        return
    end

    local spell_names = equipped_spells:map(function(spell_id)
        return res.spells[spell_id].en
    end)

    local spell_set = BlueMagicSet.new(spell_names)
    return spell_set
end

-------
-- Removes all equipped spells.
function BlueMage:remove_all_spells()
    windower.ffxi.reset_blue_magic_spells()
end

function BlueMage:equip_spells(spell_names)
    if spell_names:empty() then
        return
    end

    local actions = L{}
    actions:append(BlockAction.new(function()
        self:remove_all_spells()
    end), 'equip_remove_all_spells')
    actions:append(WaitAction.new(0, 0, 0, 1.0))

    local spell_ids = spell_names:map(function(spell_name)
        return res.spells:with('en', spell_name).id
    end):compact_map()

    local slot_num = 1
    for spell_id in spell_ids:it() do
        actions:append(EquipSpellAction.new(spell_id, slot_num))
        slot_num = slot_num + 1
    end

    actions:append(BlockAction.new(function()
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, done!")
    end), 'equip_spells_done')

    local equip_action = SequenceAction.new(actions, 'equip_spell_set', true)
    equip_action.display_name = "Equipping spells"
    equip_action.priority = ActionPriority.highest
    equip_action.max_duration = 15

    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Give me a sec, I'm updating my spells...")

    self.spells_action_queue:push_action(equip_action, true)
end

-------
-- Returns a list of spells only usable under the effects of Unbridled Learning
-- or Unbridled Wisdom.
-- @treturn list List of spell names
function BlueMage:get_unbridled_spells()
    return L{
        'Thunderbolt', 'Harden Shell', 'Absolute Terror', 'Gates of Hades',
        'Tourbillion', 'Pyric Bulwark', 'Bilgestorm', 'Bloodrake',
        'Droning Whirlwind', 'Carcharian Verve', 'Blistering Roar',
        'Uproot', 'Crashing Thunder', 'Polar Roar', 'Mighty Guard',
        'Cruel Joke', 'Cesspool', 'Tearing Gust',
    }
end

-------
-- Returns a list of conditions for an ability.
-- @tparam Spell|JobAbility ability The ability
-- @treturn list List of conditions
function BlueMage:get_conditions_for_ability(ability)
    local conditions = Job.get_conditions_for_ability(self, ability)
    if self:get_unbridled_spells():contains(ability:get_name()) then
        conditions:append(JobAbilityRecastReadyCondition.new('Unbridled Learning'))
    end
    return conditions
end

return BlueMage