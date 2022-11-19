--[[Copyright © 2019, Cyrite

Farm v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'Follow'
_addon.author = 'Cyrite'
_addon.version = '1.0.0'
_addon.command = 'follow'
_addon.commands = {'follow_ext'}

require('chat')
require('lists')
require('coroutine')
require('sets')
require('logger')
require('cylibs/Cylibs-Include')

local IpcMessage = require('cylibs/messages/ipc_message')
local FollowTargetMessage = require('cylibs/messages/follow_message')
local UnfollowTargetMessage = require('cylibs/messages/unfollow_message')
local ZoneMessage = require('cylibs/messages/zone_message')

local packets = require('packets')

config = require('config')

defaults = {}
defaults.target = "Cyrite"
defaults.distance = 6
defaults.maxfollowdistance = 35
defaults.maxfollowpoints = 100
defaults.keybind = 'f1'
defaults.follow_mode = 'Auto'

settings = config.load(defaults)

-- Properties

local handlers = {}
local followers = S{}
local follow_distance = defaults.distance
local current_target = nil
local paused = true
local used_warp = false
local action_queue = ActionQueue.new(nil, false, settings.maxfollowpoints)

state.FollowMode = M{['description'] = 'Follow Mode', 'Auto', 'Lock', 'Off'}

function load_user_files(main_job_id, sub_job_id)
end

-- Actions

function cancel_actions()
	action_queue:clear()
end

local function follow_target(target_name, distance)
	if current_target ~= nil then
		stop()
	end

	target_name = target_name:gsub("^%l", string.upper)

	local player = windower.ffxi.get_player()
	if target_name == player.name or not check_target_in_range(target_name) then 
		return "Invalid target %s":format(target_name)
	end

	paused = false

	current_target = target_name
	follow_distance = tonumber(distance) or settings.distance
	
	settings.target = current_target

	windower.ffxi.run(false)
	windower.send_ipc_message("follow %s %s":format(target_name, windower.ffxi.get_player().name))
	
	notice("Now following %s with mode %s":format(target_name, state.FollowMode.current))
end

function set_distance(distance)
	if current_target ~= nil and tonumber(distance) ~= nil then
		follow_distance = tonumber(distance)
		follow_target(current_target, follow_distance)
	end
end

function pause()
	if not current_target or paused then
		return
	end

	paused = true

	action_queue:clear()

	windower.ffxi.run(false)
	windower.send_ipc_message("unfollow %s %s":format(current_target, windower.ffxi.get_player().name))
end

function stop()
	pause()
	
	current_target = nil

	addon_message(123, 'Follow cancelled')
end

-- Helpers

function addon_message(color,str)
	windower.add_to_chat(color, _addon.name..': '..str)
end

function notify_followers()

end

function check_target_in_range(target_name)
	local follow_target = windower.ffxi.get_mob_by_name(target_name)
	if follow_target then
		local distance = ffxi_util.distance(ffxi_util.get_player_position(), ffxi_util.get_mob_position(follow_target.name))
		if distance <= settings.maxfollowdistance then
			return true
		end
	end
	return false
end

function check_valid_target()
	if not current_target or current_target:length() == 0 then
		return false
	end

	if check_target_in_range(current_target) then
		return true
	end
	return false
end

-- Handlers

function postrender()
	if paused then
		return
	end

	if not check_valid_target() then
		return
	end

	local follow_target = windower.ffxi.get_mob_by_name(current_target)
	if action_queue:last() == nil or action_queue:last():distance(follow_target.x, follow_target.y, follow_target.z) > 1 then
		--if math.abs(follow_target.z - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).z) > 1 or math.sqrt(follow_target.distance) > follow_distance then
			action_queue:push_action(WalkAction.new(follow_target.x, follow_target.y, follow_target.z, 2))
		--end
	end
end

function check_incoming_chunk(id,original,modified,injected,blocked)
end

function check_outgoing_chunk(id,data,modified,is_injected,is_blocked)
	if id == 0x05B then
		local p = packets.parse('outgoing', data)
		
		local target = windower.ffxi.get_mob_by_id(p['Target'])
		
		local warps = L{ 
			'Waypoint', 
			'Home Point', 
			'Enigmatic Device', 
			'Survival Guide', 
			'Undulating Confluence' 
		}
		for prefix in warps:it() do
			if target.name:sub(1, #prefix) == prefix then
				used_warp = true
			end
		end
	end
end

function ipc_message_received(message)
	local args = L{}
	for arg in message:gmatch("%w+") do 
		args:append(arg)
	end

	if args:length() > 0 then
		local command = args[1]
		if command == 'follow' then
			local follow_message = FollowTargetMessage.new(message)
			if follow_message:get_leader() == windower.ffxi.get_player().name then
				followers:add(follow_message:get_follower())
				notice("Added follower")
			end
		elseif command == 'unfollow' then
			local unfollow_message = UnfollowTargetMessage.new(message)
			if unfollow_message:get_leader() == windower.ffxi.get_player().name then
				followers:remove(unfollow_message:get_follower())
				notice("Removed follower")
			end
		elseif command == 'zone' then
			local zone_message = ZoneMessage.new(message)
			if zone_message:get_new_zone_id() ~= windower.ffxi.get_info().zone then
				local zone_target = windower.ffxi.get_mob_by_name(zone_message:get_target_name())
				if zone_target and zone_target.name == current_target then
					local to_pos = player_util.get_point_in_direction(
						ffxi_util.get_player_position(), 
						ffxi_util.get_mob_position(zone_target.name), 
						10
					)
					-- Run towards the zone
					--local direction = ffxi_util.get_direction_to_point(to_pos)
					--windower.ffxi.run(direction)
				end
			end
		else
			notice("Unknown command %s":format(command))
		end
	end
end

function keyboard(dik, pressed, flags, blocked)
	if pressed and paused == false then
		if state.FollowMode.value ~= 'Lock' then
			local arrow_keys = L{ 17, 30, 31, 32 }
			if arrow_keys:contains(dik) then
				disable()
				cancel_actions()
			end
		end
	end
end

function toggle_enabled()
	if paused then
		enable()
	else 
		disable()
	end
end

function enable()
	paused = false
	notice("Following started")
end

function disable()
	paused = true
	notice("Following paused")
end

function zone(new_id, old_id)
	cancel_actions()
	
	if not used_warp then
		windower.send_ipc_message("zone %s %s %s":format(windower.ffxi.get_player().name, new_id, old_id))
	end

	used_warp = false
end

-- Addon commands

handlers['target'] = follow_target
handlers['distance'] = set_distance
handlers['stop'] = stop
handlers['toggle'] = toggle_enabled

local function addon_command(cmd, ...)
	local cmd = cmd or 'help'

	if handlers[cmd] then
		local msg = handlers[cmd](unpack({...}))
		if msg then
			error(msg)
		end
	else
		if not L{'cycle', 'set'}:contains(cmd) then
			error("Unknown command %s":format(cmd))
		end
	end
end

windower.register_event('addon command', addon_command)

-- Setup & Teardown

function load_chunk_event()
    incoming_chunk = windower.register_event('incoming chunk', check_incoming_chunk)
    outgoing_chunk = windower.register_event('outgoing chunk', check_outgoing_chunk)
	
	windower.send_command('bind '..settings.keybind..' follow toggle')

	load_user_files(windower.ffxi.get_player().main_job_id, windower.ffxi.get_player().sub_job_id)
end

function unload_chunk_event()
    windower.unregister_event(incoming_chunk)
    windower.unregister_event(outgoing_chunk)

	windower.send_command('unbind '..settings.keybind)
end

function reset()
	stop()
end

function unloaded()
    if user_events then
        reset()
        for _,event in pairs(user_events) do
            windower.unregister_event(event)
        end
        user_events = nil
		unload_chunk_event()
    end
end

function loaded()
    if not user_events then
        user_events = {}
        user_events.postrender = windower.register_event('postrender', postrender)
		user_events.keyboard = windower.register_event('keyboard', keyboard)
		user_events.zone_change = windower.register_event('zone change', zone)
		user_events.ipc_message_received = windower.register_event('ipc message', ipc_message_received)
        coroutine.schedule(load_chunk_event,0.1)
    end

	state.FollowMode:set(settings.follow_mode)

	if settings.target then
		follow_target(settings.target)
	end
end

windower.register_event('login','load', loaded)
windower.register_event('logout', 'unload', unloaded)


