---------------------------
-- Utility functions for buffs.
-- @class module
-- @name BuffUtil

_libs = _libs or {}

require('lists')

local res = require('resources')
local job_abilities_ext = require('cylibs/res/job_abilities')
local spells_ext = require('cylibs/res/spells')

local buff_util = {}

_raw = _raw or {}

_libs.buff_util = buff_util

local debuffs = T{
	[2] = S{253,259,678}, --Sleep
	[3] = S{220,221,225,350,351,716}, --Poison
	[4] = S{58,80,341,644,704}, --Paralyze
	[5] = S{254,276,347,348}, --Blind
	[6] = S{59,687,727}, --Silence
	[7] = S{255,365,722}, --Break
	[9] = S{}, -- curse
	[11] = S{258,531}, --Bind
	[12] = S{216,217,708}, --Gravity
	[13] = S{56,79,344,345,703}, --Slow
	[15] = S{751}, -- doom
	[19] = S{}, -- sleep
	[20] = S{}, -- curse
	[21] = S{286,472,884}, --addle/nocturne
	[28] = S{575,720,738,746}, --terror
	[31] = S{682}, --plague
	[128] = S{}, -- Burn
	[129] = S{}, -- Frost
	[130] = S{}, -- Choke
	[131] = S{}, -- Rasp
	[132] = S{}, -- Shock
	[133] = S{}, -- Drown
	[134] = S{}, -- Dia
	[135] = S{}, -- Bio
	[136] = S{240,705}, --str down
	[137] = S{238}, --dex down
	[138] = S{237}, --VIT down
	[139] = S{236,535}, --AGI down
	[140] = S{235,572,719}, --int down
	[141] = S{239}, --mnd down
	[144] = S{}, -- max hp down
	[145] = S{}, -- max mp down
	[146] = S{524,699}, --accuracy down
	[147] = S{319,651,659,726}, --attack down
	[148] = S{610,841,842,882}, --Evasion Down
	[149] = S{717,728,651}, -- defense down
	[156] = S{112,707,725}, --Flash
	[167] = S{656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[186] = S{}, -- Helix
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[193] = S{463,471,376,377}, --lullabies
	[194] = S{421,422,423}, --elegy
	[217] = S{454,455,456,457,458,459,460,461,871,872,873,874,875,876,877,878}, --threnodies
	[404] = S{843,844,883}, --Magic Evasion Down
	[597] = S{879}, --inundation

}

local aura_debuff_names = L{'Defense Down','Magic Atk. Down','Magic Def. Down','Accuracy Down','Evasion Down','Magic Acc. Down','Magic Evasion Down','disease'}

-- Buffs that are exceptions and not linked to their spell
local spell_id_to_buff = T{
}

-- Set of buffs that conflict with a given buff and cannot be overridden
local buff_conflicts = T{
	[43] = S{187, 188}, -- Refresh = Sublimation: Active/Sublimation: Complete
	[68] = S{460}, -- Warcry
	[460] = S{68}, -- Blood Rage
	[33] = S{13, 565, 265, 581}, -- Haste
	[358] = S{401}, -- Light Arts/Addendum: White
	[359] = S{402}, -- Dark Arts/Addendum: Black
	[531] = S{535}, -- Vallation
	[535] = S{531}, -- Valiance

	-- Shadows
	[66] = S{66,444,445,446},
	[444] = S{66,444,445,446},
	[445] = S{66,444,445,446},
	[446] = S{66,444,445,446},
}


-------
-- Determines if the player has a given buff active.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam list player_buff_ids List of active buff ids, included for performance reasons (optional)
-- @treturn Bool True if the buff is active and false otherwise.
function buff_util.is_buff_active(buff_id, player_buff_ids)
	if player_buff_ids == nil then
		player_buff_ids = L{}
		local player = windower.ffxi.get_player()
		if player then
			player_buff_ids = L(player.buffs)
		end
	end
	return player_buff_ids:contains(buff_id)
end

-------
-- Determines how many of the given buff a player has active.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam list buff_ids List of active buff ids, required for performance reasons
-- @treturn number Number of the given buff a player has active
function buff_util.buff_count(buff_id, buff_ids)
	if not buff_ids then
		return 0
	end
	return L(buff_ids):count(function(b) return b == buff_id end)
end

-------
-- Determines if the player has any of the given buffs active.
-- @tparam list buff_ids List of buff ids (see buffs.lua)
-- @tparam list player_buff_ids List of active buff ids, included for performance reasons (optional)
-- @treturn Bool True if any buff is active and false otherwise.
function buff_util.is_any_buff_active(buff_ids, player_buff_ids)
	if player_buff_ids == nil then
		player_buff_ids = L{}
		local player = windower.ffxi.get_player()
		if player then
			player_buff_ids = L(player.buffs)
		end
	end
	for buff_id in buff_ids:it() do
		if buff_util.is_buff_active(buff_id, player_buff_ids) then
			return true
		end
	end
	return false
end

-------
-- Returns the buff name for the given buff id.
-- @tparam string buff_id Buff id (see buffs.lua)
-- @treturn string Buff name (see buffs.lua)
function buff_util.buff_name(buff_id)
	return res.buffs:with('id', buff_id).en
end

-------
-- Returns the buff id for the given buff name.
-- @tparam string buff_name Localized buff name
-- @treturn number Buff id (see buffs.lua)
function buff_util.buff_id(buff_name)
	local buff_names = L{ buff_name, string.lower(buff_name), buff_name:gsub("^%l", string.upper) }
	for buff_name in buff_names:it() do
		local buff = res.buffs:with('en', buff_name)
		if buff == nil then
			buff = res.buffs:with('enl', buff_name)
		end
		if buff then
			return buff.id
		end
	end
	return nil
end

-------
-- Filters the list of buff_ids and returns the full metadata for buffs only.
-- @tparam list buff_ids List of buff ids (see buffs.lua)
-- @treturn list Full metadata for the buff (see buffs.lua)
function buff_util.buffs_for_buff_ids(buff_ids)
	return list.subtract(L(buff_ids), L(debuffs:keyset()))
end

-------
-- Returns whether the given buff conflicts with a player's existing buffs.
-- @tparam number buff_id Buff ids (see buffs.lua)
-- @tparam list buff_ids List of buff ids (see buffs.lua)
-- @treturn Boolean True if the given buff conflicts with a player's existing buffs and false otherwise
function buff_util.conflicts_with_buffs(buff_id, buff_ids)
	buff_ids = buff_ids or L{}
	local conflicting_buff_ids = buff_conflicts[buff_id]
	if conflicting_buff_ids then
		return L(set.intersection(conflicting_buff_ids, S(buff_ids))):length() > 0
	end
	return false
end

-------
-- Returns which of the given buffs are overwritten by a buff.
-- @tparam number buff_id Buff ids (see buffs.lua)
-- @tparam list buff_ids List of buff ids (see buffs.lua)
-- @treturn list List of buff ids that are overwritten
function buff_util.buffs_overwritten(buff_id, buff_ids)
	buff_ids = buff_ids or L{}
	local spells = L(res.spells:with_all('status', buff_id)):map(function(spell) return L(spell.overwrites or {}) end):flatten()

	local statuses = S(spells:map(function(spell_id) return res.spells:with('id', spell_id).status end)):filter(function(status_id) return status_id ~= buff_id and buff_ids:contains(status_id)  end)
	return statuses
end

-------
-- Returns the full metadata for the debuff associated with the given spell.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn BuffMetadata Full metadata for the debuff (see buffs.lua)
function buff_util.debuff_for_spell(spell_id)
	local spell = res.spells:with('id', spell_id)
	if spell then
		if spell.status == nil then
			spell = spells_ext:with('id', spell_id)
		end
		if spell and spell.status then
			return res.buffs:with('id', spell.status)
		end
	end
	return nil
end

-------
-- Filters the list of buff_ids and returns the full metadata for debuffs only.
-- @tparam list buff_ids List of buff ids (see buffs.lua)
-- @treturn list Full metadata for the debuff (see buffs.lua)
function buff_util.debuffs_for_buff_ids(buff_ids)
	return set.intersection(S(buff_ids), S(debuffs:keyset()))
end

-------
-- Returns a list of debuff names for auras.
-- @treturn list Debuff names (see buffs.lua)
function buff_util.debuffs_for_auras()
	return aura_debuff_names
end

-------
-- Returns the full metadata for the buff associated with the given spell.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn BuffMetadata Full metadata for the buff (see buffs.lua)
function buff_util.buff_for_spell(spell_id)
	if spell_id_to_buff[spell_id] then
		return res.buffs:with('id', spell_id_to_buff[spell_id])
	else
		local spell = res.spells:with('id', spell_id)
		if spell.status == nil then
			spell = spells_ext:with('id', spell_id)
		end
		if spell ~= nil then
			return res.buffs:with('id', spell.status)
		end
		return nil
	end
end

-------
-- Returns the full metadata for the spell associated with the given buff.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @treturn SpellMetadata Full metadata for the spell (see spells.lua)
function buff_util.spell_for_buff(buff_id)
	local buff = res.buffs:with('id', buff_id)
	if buff then
		return res.spells:with('status', buff.id)
	end
	return nil
end

-------
-- Returns the full metadata for the debuff associated with the given job ability.
-- @tparam number job_ability_id Id in job_abilities.lua
-- @treturn BuffMetadata Full metadata for the buff (see buffs.lua)
function buff_util.buff_for_job_ability(job_ability_id)
	local job_ability = res.job_abilities:with('id', job_ability_id)
	if job_ability.status == nil then
		job_ability = job_abilities_ext:with('id', job_ability_id)
	end
	if job_ability and job_ability.status then
		return res.buffs:with('id', job_ability.status)
	end
	return nil
end

-------
-- Returns the full metadata for the job ability that gives a the specified buff.
-- @tparam number buff_id Id Buff id
-- @treturn JobAbilityMetadata Full metadata for the job ability (see job_abilities.lua)
function buff_util.job_ability_for_buff(buff_id)
	local job_ability = res.job_abilities:with('status', buff_id)
	if job_ability == nil then
		job_ability = job_abilities_ext:with('status', buff_id)
	end
	return job_ability
end

-------
-- Cancels the buff with the given buff_id.
-- @tparam number buff_id Buff id (see buffs.lua)
function buff_util.cancel_buff(buff_id)
	if res.buffs[buff_id] then
		windower.ffxi.cancel_buff(buff_id)
	end
end

-------
-- Determines if the player has a food effect active.
-- @treturn Bool True if the player has a food effect active and false otherwise.
function buff_util.is_food_active()
	return buff_util.is_buff_active(251)
end

-------
-- Determines if the player has ionis active.
-- @treturn Bool True if the player has ionis active and false otherwise.
function buff_util.is_ionis_active()
	return buff_util.is_buff_active(512)
end

-------
-- Determines if aftermath is active.
-- @tparam buff_ids (optional) Buff ids, defaults to player's buff ids if none specified
-- @treturn Bool True if any aftermath is active
function buff_util.is_aftermath_active(buff_ids)
	return buff_util.is_any_buff_active(L{ 270, 271, 272, 273 }, buff_ids)
end

-------
-- Determines if the player has artisenal knowledge active.
-- @treturn Bool True if the player has artisenal knowledge active and false otherwise.
function buff_util.is_artisenal_knowledge_active()
	return buff_util.is_buff_active(616)
end

-------
-- Returns the full buff metadata for the player's active synthesis support.
-- @treturn BuffMetadata Full metadata for the buff if synthesis support is active and nil otherwise
function buff_util.active_synth_support()
	local synth_support_buff_ids = L{ 
		235, 236, 237, 
		238, 239, 240, 
		241, 242, 243 
	}
	for buff_id in synth_support_buff_ids:it() do
		if buff_util.is_buff_active(buff_id) then
			return res.buffs[buff_id]
		end
	end
	return nil
end

function buff_util.is_debuff(debuff_id)
	return debuffs[debuff_id] ~= nil
end

function buff_util.get_all_debuffs()
	return L(T(debuffs):keyset()):map(function(debuff_id)
		return res.buffs[debuff_id].en:gsub("^%l", string.upper)
	end)
end

return buff_util