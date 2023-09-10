---------------------------
-- Utility functions for pets.
-- @class module
-- @name pet_util

_libs = _libs or {}

local math = require('math')
require('tables')
require('vectors')

local pet_util = {}

_raw = _raw or {}

_libs.pet_util = pet_util

-------
-- Determines if the player has a pet.
-- @treturn Boolean True if the player has a pet, false otherwise.
function pet_util.has_pet()
	return windower.ffxi.get_mob_by_target('pet') ~= nil
end

-------
-- Returns the player's pet.
-- @treturn MobMetadata Full pet metadata, or nil if the player does not have a pet.
function pet_util.get_pet()
	return windower.ffxi.get_mob_by_target('pet')
end

-------
-- Determines if the player's pet is idle.
-- @treturn Boolean True if the player's pet is idle or the player does not have a pet and false otherwise.
function pet_util.pet_idle()
	local player = windower.ffxi.get_player()
	if player ~= nil then
		local pet = windower.ffxi.get_mob_by_target('pet')
		if pet ~= nil then
			return pet.status == 0
		end
	end
	return true
end

-------
-- Determines the name of the player's pet.
-- @treturn String The name of the player's pet if they have one and nil otherwise.
function pet_util.pet_name()
	local pet = windower.ffxi.get_mob_by_target('pet')
	if pet ~= nil then
		return pet.name
	end
	return nil
end

return pet_util