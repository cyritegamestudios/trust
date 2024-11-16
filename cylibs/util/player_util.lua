--[[
This library provides a set of util functions for players.
]]

_libs = _libs or {}

local math = require('math')
require('tables')
require('vectors')

local player_util = {}

_raw = _raw or {}

_libs.player_util = player_util

function player_util.stop_moving()
	local function check_movement(retry_count)
		if retry_count == 0 then
			return
		end

		windower.ffxi.follow()
		windower.ffxi.run(false)
		
		coroutine.sleep(0.5)
		
		check_movement(retry_count - 1)
	end
	check_movement(4)
end

function player_util.get_direction_in_degrees(player_id)
	local player = windower.ffxi.get_mob_by_id(player_id)
	if player ~= nil then
		local dir = math.floor(player.facing * 10000)/10000
		return math.deg(dir)
	end
	return 0
end

function player_util.get_player_position()
	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
	if not player then return end

	local v = vector.zero(3)

	v[1] = player.x
	v[2] = player.y
	v[3] = player.z

	return v
end

function player_util.distance(v1, v2)
	if not v1 or not v2 then
		return 0
	end

	return math.sqrt((v1[1]-v2[1])^2+(v1[2]-v2[2])^2+(v1[3]-v2[3])^2)
end

function player_util.find_closest_mob(target_mobs, black_list)
	local player = windower.ffxi.get_player()
	local player_mob = windower.ffxi.get_mob_by_id(player.id)
	local closest_mob = nil

	local mob_array = windower.ffxi.get_mob_array()
    for i, mob in pairs(mob_array) do
    	local deltaZ = math.abs(player_mob.z - mob.z)
		
		-- Check to see if mob is in target_mob list
		local is_target_mob = false
		for target_mob in target_mobs:it() do
			if string.match(mob.name, target_mob) and not black_list:contains(mob.name) then
				is_target_mob = true
			end
		end
		
    	if mob.id ~= player.id and is_target_mob and mob.hpp > 0 and (mob.claim_id == 0 or mob.claim_id == player.id) and mob.valid_target and (closest_mob == nil or mob.distance < closest_mob.distance) and deltaZ < 10 then
			closest_mob = mob
        end
    end
    return closest_mob
end

function player_util.get_point_in_direction(v1, v2, distance)
	local v = vector.zero(3)

	v[1] = v2[1] - v1[1]
	v[2] = v2[2] - v1[2]
	v[3] = v2[3] - v1[3]
	
	v = vector.normalize(v)
	
	local result = vector.zero(3)
	
	result[1] = v1[1] + v[1]*distance
	result[2] = v1[2] + v[2]*distance
	result[3] = v1[3] + v[3]*distance

	return result
end

function player_util.player_in_party(player_name)
	if player_name == windower.ffxi.get_player().name then
		return true
	end
	for i, party_member in pairs(windower.ffxi.get_party()) do
        if type(party_member) == 'table' and party_member.mob then
			if party_member.name == player_name then
				return true
			elseif party_member.mob.pet_index ~= nil then 
				local party_member_pet = windower.ffxi.get_mob_by_index(party_member.mob.pet_index)
				if party_member_pet ~= nil and party_member_pet.name == player_name then
					return true
				end
			end
        end
    end
	return false
end

function player_util.get_party_leader()
	local player_id = windower.ffxi.get_party().party1_leader
	if player_id ~= nil then
		return windower.ffxi.get_mob_by_id(player_id)
	end
	return nil
end

function player_util.party_claimed(target_index)
	local target = windower.ffxi.get_mob_by_index(target_index)
	if target ~= nil and target.claim_id ~= nil then
		local claimed_by = windower.ffxi.get_mob_by_id(target.claim_id)
		if claimed_by ~= nil and player_util.player_in_party(claimed_by.name) then
			return true
		end
	end
	return false
end

function player_util.get_player_target(player_name)
	if player_name == nil then
		return nil
	end
	local mob = windower.ffxi.get_mob_by_name(player_name)
	if mob ~= nil then
		return windower.ffxi.get_mob_by_index(mob.target_index)
	end
	return nil
end

function player_util.in_battle()
	return windower.ffxi.get_mob_by_target("bt") ~= nil
end

function player_util.get_player_main_job_name_short()
	local main_job_id = tonumber(windower.ffxi.get_player().main_job_id)

	if main_job_id and res.jobs[main_job_id] then
        player.main_job_id = main_job_id
        if res.jobs[main_job_id] then
            return res.jobs[main_job_id]['ens']
        end
    end
	return nil
end

function player_util.is_engaged()
	local player = windower.ffxi.get_player()
	if player ~= nil then return player.status == 1 end
	return false
end

function player_util.face(target)
	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
	if player == nil then
		return
	end

	local angle = (math.atan2((target.y - player.y), (target.x - player.x))*180/math.pi)*-1
	windower.ffxi.turn((angle):radian())
end

function player_util.face_away(target)
	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

	local angle = (math.atan2((target.y - player.y), (target.x - player.x))*180/math.pi)*-1
	windower.ffxi.turn(((angle + 180) % 360):radian())
end

function player_util.get_job_abilities()
	local abilities = windower.ffxi.get_abilities()

	local result = L{}
	for _, value in pairs(abilities.job_abilities) do
		result:append(value)
	end
	return result
end

function player_util.get_job_ability_recast(job_ability_name)
	local job_abilities = player_util.get_job_abilities()

	if not job_abilities:contains(res.job_abilities:with('en', job_ability_name).id) then return false end

	local recast_id = res.job_abilities:with('en', job_ability_name).recast_id
	return windower.ffxi.get_ability_recasts()[recast_id]
end

function player_util.get_current_strategem_count()
	if not buff_util.is_any_buff_active(L{ buff_util.buff_id('Light Arts'), buff_util.buff_id('Addendum: White'), buff_util.buff_id('Dark Arts'), buff_util.buff_id('Addendum: Black') }) then
		return 0
	end

	-- returns recast in seconds.
	local allRecasts = windower.ffxi.get_ability_recasts()
	local stratsRecast = allRecasts[231]
	if stratsRecast == nil then return 0 end

	local maxStrategems = math.floor((windower.ffxi.get_player().main_job_level + 10) / 20)

	local fullRechargeTime = 33*5--4*60

	local currentCharges = math.floor(maxStrategems - maxStrategems * stratsRecast / fullRechargeTime)

	return math.max(currentCharges, 0)
end

function player_util.get_ready_charges()
	if not pet_util.has_pet() then
		return 0
	end

	local abil_recasts = windower.ffxi.get_ability_recasts()
	local readyRecast = abil_recasts[102]

	local maxCharges = 3

	local base_chargetimer = 30

	local job_points = job_util.get_job_points('BST')
	if job_points > 100 then
		base_chargetimer = base_chargetimer - 5
	end

	base_chargetimer = base_chargetimer - (2 * windower.ffxi.get_player().merits.sic_recast)

	local ReadyChargeTimer = base_chargetimer

	-- The *# is your current recharge timer.
	local fullRechargeTime = 3*ReadyChargeTimer

	local currentCharges = math.floor(maxCharges - maxCharges * readyRecast / fullRechargeTime)

	return currentCharges
end

-- NOTE:  this currently causes all of the items data to constantly be in memory which
-- bloats the addon size. Figure out another way to do this with packets.
function player_util.has_item(item_name, quantity)
	quantity = quantity or 1
	local item = res.items:with('en', item_name)
	if item then
		local items = windower.ffxi.get_items(0)
		for _, item_info in ipairs(items) do
			if item_info.id ~= 0 and item_info.id == item.id and item_info.count >= quantity then
				return true
			end
		end
	end
	return false
end

function player_util.get_current_target()
	local target_index = windower.ffxi.get_player().target_index
	if target_index and target_index ~= 0 then
		return windower.ffxi.get_mob_by_index(target_index)
	end
	return nil
end

function player_util.get_mounts()
	local possible_mounts = L{}
	for _, mount in pairs(res.mounts) do
		possible_mounts:append(mount.en:lower())
	end
	local allowed_mounts_set = S{}
	local kis = windower.ffxi.get_key_items()

	for _, id in ipairs(kis) do
		local ki = res.key_items[id]
		if ki ~= nil then
			if ki.category == 'Mounts' and ki.en ~= "trainer's whistle" then
				local mount_index = possible_mounts:find(function(possible_mount)
					return windower.wc_match(ki.en:lower(), '♪' .. possible_mount .. '*')
				end)
				local mount = possible_mounts[mount_index]
				allowed_mounts_set:add(mount)
			end
		end
	end
	return L(allowed_mounts_set):map(function(mount)
		return mount:gsub("(%a)(%w*)", function(first, rest)
			return first:upper() .. rest:lower()
		end)
	end)
end

return player_util