---------------------------
-- Utility functions for spells.
-- @class module
-- @name SpellUtil

_libs = _libs or {}

local buff_util = require('cylibs/util/buff_util')
local res = require('resources')
local spells_ext = require('cylibs/res/spells')
local tables_ext = require('cylibs/util/extensions/tables')

local spell_util = {}

_raw = _raw or {}

_libs.spell_util = spell_util

-- Spells that come from things like items
local spells_whitelist = L{
    'Honor March'
}

local aoe_spells = L{
    'Stonega', 'Stonega II', 'Stonega III', 'Stoneja', 'Stonera', 'Stonera II', 'Stonera III',
    'Aeroga', 'Aeroga II', 'Aeroga III', 'Aeroja', 'Aerora', 'Aerora II', 'Aerora III',
    'Blizzaga', 'Blizzaga II', 'Blizzaga III', 'Blizzaja', 'Blizzara', 'Blizzara II', 'Blizzara III',
    'Firaga', 'Firaga II', 'Firaga III', 'Firaja', 'Fira', 'Fira II', 'Fira III',
    'Waterga', 'Waterga II', 'Waterga III', 'Waterja', 'Watera', 'Watera II', 'Watera III',
    'Thundaga', 'Thundaga II', 'Thundaga III', 'Thundaja', 'Thundara', 'Thundara II', 'Thundara III',
    'Banishga', 'Banishga II',
    'Meteor'
}

-------
-- Returns the spell id for the given localized spell name.
-- @tparam string spell_name Localized spell name
-- @treturn number Spell id (see spells.lua)
function spell_util.spell_id(spell_name)
    return res.spells:with('en', spell_name).id
end

-------
-- Returns the spell name for the given spell id.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn string spell_name Localized spell name
function spell_util.spell_name(spell_id)
    return res.spells:with('id', spell_id).en
end

-------
-- Returns the id for the buff associated with the given spell.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn number Buff id (see buffs.lua)
function spell_util.buff_id_for_spell(spell_id)
    local spell = res.spells:with('id', spell_id)
    if spell then
        if spell.status then
            return res.buffs:with('id', spell.status).id
        elseif spells_ext:with('id', spell_id) then
            return spells_ext:with('id', spell_id).status
        end
    end
    return nil
end

-------
-- Returns whether the player knows a spell, either from their main job or sub job. Assumes all spells through the
-- player's current level have been learned.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn Boolean True if the player knows the given spell
function spell_util.knows_spell(spell_id)
    -- Check if spell_id exists
    local spell = res.spells[spell_id]
    -- Check get_spells to get a list of all known spells, true if known, false or nil if not known
    local spell_known = windower.ffxi.get_spells()[spell_id] or spells_whitelist:contains(spell_util.spell_name(spell_id))
    -- If both are true, check if player can cast
    if spell and spell_known then
        local player = windower.ffxi.get_player()
        -- Main job can cast spell
        local main_job_level = player.main_job_level
        -- Job point spell
        if (spell.levels[player.main_job_id] or 0) > 99 then
            main_job_level = job_util.get_job_points(res.jobs[player.main_job_id]['ens'])
        end
        -- Main job can cast (including JP)
        if spell.levels[player.main_job_id] and main_job_level >= spell.levels[player.main_job_id] then
            return true
        end
        -- Sub job can cast
        if spell.levels[player.sub_job_id] and player.sub_job_level >= spell.levels[player.sub_job_id] then
            return true
        end
    end
    return false
end

-------
-- Returns the highest tier spell that grants the given buff, e.g. given the buff_id for Refresh, returns Refresh III.
-- Will only return spells the player can cast.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam string prefix Buff name prefix (optional) (see buffs.lua)
-- @treturn SpellMetadata Spell metadata (see spells.lua)
function spell_util.highest_spell_for_buff_id(buff_id, prefix)
    local highest_tier_spell_id = nil
    local spells = res.spells:with_all('status', buff_id)
    if spells:empty() then
        spells = spells_ext:with_all('status', buff_id)
    end
    if prefix then
        spells = spells:filter(function(spell) return spell.en:contains(prefix)  end)
    end
    for spell in spells:it() do
        if spell_util.knows_spell(spell.id) and spell_util.spell_overwrites_spell(spell.id, highest_tier_spell_id) then
            highest_tier_spell_id = spell.id
        end
    end
    return res.spells[highest_tier_spell_id]
end

-------
-- Returns whether the first spell overwrites the second spell.
-- @tparam number spell1_id First spell id (see spells.lua)
-- @tparam number spell2_id Second spell id (see spells.lua)
-- @treturn Boolean True if the first spell overwrites the second spell
function spell_util.spell_overwrites_spell(spell1_id, spell2_id)
    if spell2_id == nil then return true end

    local spell1_metadata = res.spells:with('id', spell1_id)

    local overwrites = L(spell1_metadata.overwrites or {})
    if overwrites:empty() and spells_ext:with('id', spell1_metadata.id) then
        overwrites = L(spells_ext:with('id', spell1_metadata.id).overwrites or {})
    end

    return overwrites:contains(spell2_id)
end

-------
-- Returns whether the player can cast a spell.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn Boolean True if the player knows the spell and its recast timer is up.
function spell_util.can_cast_spell(spell_id)
    return spell_util.get_spell_recast(spell_id) == 0 and spell_util.knows_spell(spell_id)
end

-------
-- Returns the spell recast for the given spell. Note that this will return 0 if a player has learned a spell but
-- does not have access to it on their current job.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn number Recast time (in seconds)
function spell_util.get_spell_recast(spell_id)
    -- Honor March
    if spell_id == 417 then return 0 end

    local all_spells = windower.ffxi.get_spells()
    local recast_times = windower.ffxi.get_spell_recasts()

    if not all_spells[spell_id] then return 9999 end

    return recast_times[spell_id]
end

-------
-- Returns whether the spell is on cooldown.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn boolean Whether the spell is on cooldown.
function spell_util.is_spell_on_cooldown(spell_id)
    local recast_time = spell_util.get_spell_recast(spell_id)
    return recast_time > 0
end

-------
-- Returns whether the player is able to cast spells (e.g. if they are silenced).
-- @treturn Boolean True if the player can cast spells and false otherwise
function spell_util.can_cast_spells()
    if L(windower.ffxi.get_player().buffs):contains(L{2,7,14,19,28,29}) then
        return false
    end
    return true
end

-------
-- Returns the spell metadata for all spells matching the given filter.
-- @treturn list List of SpellMetadata (see res/spells.lua).
function spell_util.get_spells(filter)
    local all_spell_ids = L(T(windower.ffxi.get_spells()):keyset())
            :filter(function(spellId) return res.spells[spellId] ~= nil and spell_util.knows_spell(spellId) end)
    local all_spells = all_spell_ids:map(function(spell_id) return res.spells[spell_id] end)
            :filter(function(spell) return filter(spell)  end)
    return all_spells
end

-------
-- Returns true if the spell_id corresponds to a barspell that improves resistance to an element.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn boolean True if a barspell, false otherwise
function spell_util.is_barelement(spell_id)
    return L{60,61,62,63,64,65,66,67,68,69,70,71}:contains(spell_id)
end

-------
-- Returns true if the spell_id corresponds to a barspell that improves resistance to a status effect.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn boolean True if a barspell, false otherwise
function spell_util.is_barstatus(spell_id)
    return L{72,73,74,75,76,77,78,84,85,86,87,88,89,90,91,92}:contains(spell_id)
end

-------
-- Returns the spell_name with all roman numerals removed.
-- @tparam string spell_name Spell name (e.g. Cure IV)
-- @treturn string Spell name with roman numerals removed
function spell_util.base_spell_name(spell_name)
    local patterns = L{"II", "III", "IV", "V", "VI", "VIII"}
    for pattern in patterns:it() do
        if string.match(spell_name, pattern) then
            return spell_name:match("%S+")
        end
    end
    return spell_name
end

-------
-- Returns a list of valid targets for the given spell.
-- @tparam number spell_id Spell id or spell name (see res/spells.lua)
-- @treturn list List of valid targets (e.g. Self, Party, Alliance, Enemy)
function spell_util.spell_targets(spell_id)
    if type(spell_id) == 'string' then
        spell_id = res.spells:with('en', spell_id).id
    end
    local spell = res.spells[spell_id]
    if spell then
        local targets = L(spell.targets)
        if spell.type == 'BardSong' and buff_util.is_buff_active(buff_util.buff_id('Pianissimo')) then
            targets:append('Party')
        elseif spell.type == 'Geomancy' then
            targets:append('Party')
        end
        return targets
    end
    return L{}
end

-------
-- Returns whether the given offensive spell is AOE.
-- @tparam string spell_name Spell id or spell name (see res/spells.lua)
-- @treturn boolean True if the spell is AOE
function spell_util.is_aoe_spell(spell_name)
    return aoe_spells:contains(spell_name)
end

-------
-- Sorts a list of spells by element first and alphabetically within each element. Modifies the list in place.
-- @tparam list spells List of spells (see battle/spells.lua)
function spell_util.sort_by_element(spells, descending)
    local element_to_spells = {
        Fire = L{},
        Ice = L{},
        Wind = L{},
        Earth = L{},
        Lightning = L{},
        Water = L{},
        Light = L{},
        Dark = L{}
    }
    for spell in spells:it() do
        local element_name = res.elements[spell:get_spell().element].name
        element_to_spells[element_name]:append(spell)
    end

    local element_priority = L{
        'Dark',
        'Lightning',
        'Ice',
        'Fire',
        'Wind',
        'Water',
        'Earth',
        'Light'
    }

    local result = L{}
    for element in element_priority:it() do
        local spells = element_to_spells[element]
        spells:sort(function(spell1, spell2)
            if descending then
                return spell1:get_name() > spell2:get_name()
            else
                return spell1:get_name() < spell2:get_name()
            end
        end)
        result = result:extend(spells)
    end

    spells:clear()
    spells = spells:extend(result)

    return result
end

return spell_util