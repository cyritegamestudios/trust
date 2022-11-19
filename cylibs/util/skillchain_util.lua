--[[
This library provides a set of util functions for players.
]]

local math = require('math')
require('tables')
require('vectors')

local player_util = require('cylibs/util/player_util')

white_magic_nukes = {}
white_magic_nukes.light = L{'Holy II','Banish III','Holy'}

black_magic_nukes = {}
black_magic_nukes.light = L{'Thunder V','Thunder IV','Thunder III'}
black_magic_nukes.dark = L{'Blizzard V', 'Blizzard IV', 'Blizzard III'}
black_magic_nukes.fusion = L{'Fire V', 'Fire IV', 'Fire III'}
black_magic_nukes.liquefaction = L{'Fire V', 'Fire IV', 'Fire III'}
black_magic_nukes.compression = L{'Stone V', 'Stone IV', 'Stone III'}
black_magic_nukes.gravitation = L{'Stone V', 'Stone IV', 'Stone III'}

function highest_nuke_for_skillchain(skillchain_element)
	local main_job_name_short = player_util.get_player_main_job_name_short()
	
	local all_spells = windower.ffxi.get_spells()
	local recast_times = windower.ffxi.get_spell_recasts()

	if main_job_name_short == 'WHM' then
		local spells = L{}
		
		if skillchain_element == 'light' or skillchain_element == 'fusion' then
			spells = white_magic_nukes.light
		else
			return nil
		end
				
		for spell_name in white_magic_nukes.light:it() do
			local spell_id = res.spells:with('name', spell_name).id
			if spell_id and all_spells[spell_id] and recast_times[spell_id] <= 0 then
				return res.spells:with('name', spell_name)
			end
		end
	elseif main_job_name_short == 'GEO' or main_job_name_short == 'BLM' then
		local spells = L{}

		if skillchain_element == 'light' then
			spells = black_magic_nukes.light
		elseif skillchain_element == 'darkness' then
			spells = black_magic_nukes.dark
		elseif skillchain_element == 'fusion' then
			spells = black_magic_nukes.fusion
		elseif skillchain_element == 'liquefaction' then
			spells = black_magic_nukes.liquefaction
		elseif skillchain_element == 'compression' then
			spells = black_magic_nukes.compression
		elseif skillchain_element == 'gravitation' then
			spells = black_magic_nukes.gravitation
		else
			return nil
		end
		
		for spell_name in spells:it() do
			local spell_id = res.spells:with('name', spell_name).id
			if spell_id and all_spells[spell_id] and recast_times[spell_id] <= 0 then
				return res.spells:with('name', spell_name)
			end
		end
	end
	return nil
end

function next_weaponskill(previous_weaponskill_name, skillchain_element)
	return res.weapon_skills:with('name', 'Leaden Salute')
	--return res.weapon_skills:with('name', 'Savage Blade')
end