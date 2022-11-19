--[[
This library provides a set of util functions for synths.
]]

_libs = _libs or {}

require('lists')

local table = require('table')
local res = require('resources')

local synth_util = {}

_raw = _raw or {}

_libs.synth_util = synth_util

local nq_to_hq_crystal = {
	["Inferno Crystal"] = "Fire Crystal",
	["Terra Crystal"] = "Earth Crystal",
	["Torrent Crystal"] = "Water Crystal",
	["Cyclone Crystal"] = "Wind Crystal",
	["Glacier Crystal"] = "Ice Crystal",
	["Plasma Crystal"] = "Lightning Crystal",
	["Aurora Crystal"] = "Light Crystal",
	["Twilight Crystal"] = "Dark Crystal"
}

local recipe_name_to_item_name = {
	["Bewitched Dalmatica"] = "Bewitch. Dalmatica",
	["Red Grass Thread"] = "Red Grs. Thread"
}

function synth_util.get_nq_crystal(crystal)
	if crystal.en ~= nil and nq_to_hq_crystal[crystal.en] ~= nil then
		return nq_to_hq_crystal[crystal.en]
	end
	return crystal.en
end

function synth_util.match_recipe_to_item(recipe_name)
	if recipe_name == nil then return nil end
	if recipe_name_to_item_name[recipe_name] ~= nil then
		recipe_name = recipe_name_to_item_name[recipe_name]
	end
	return res.items:with('name', recipe_name)
end

function synth_util.rank_for_craft(craft_name)
	local player = windower.ffxi.get_player()
	if player ~= nil then
		local skill = player.skills[craft_name:lower()]
		if skill < 10 then
			return "Amateur"
		elseif skill < 20 then
			return "Recruit"
		elseif skill < 30 then
			return "Initiate"
		elseif skill < 40 then
			return "Novice"
		elseif skill < 50 then
			return "Apprentice"
		elseif skill < 60 then
			return "Journeyman"
		elseif skill < 70 then
			return "Craftsman"
		elseif skill < 80 then
			return "Artisan"
		elseif skill < 90 then
			return "Adept"
		elseif skill < 100 then
			return "Veteran"
		else 
			return "Expert"
		end
	end
	return ""
end

return synth_util