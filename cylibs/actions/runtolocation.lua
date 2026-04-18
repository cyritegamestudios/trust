---------------------------
-- Action representing the player running to a location.
-- @class module
-- @name RunToLocationAction

require('vectors')
require('math')
require('logger')

local DisposeBag = require('cylibs/events/dispose_bag')
local player_util = require('cylibs/util/player_util')
local Action = require('cylibs/actions/action')
local Renderer = require('cylibs/ui/views/render')
local RunToLocationAction = setmetatable({}, {__index = Action })
RunToLocationAction.__index = RunToLocationAction

function RunToLocationAction.new(x, y, z, distance, description, keep_running)
	local self = setmetatable(Action.new(0, 0, 0), RunToLocationAction)
	self.user_events = {}
	self.x = x
	self.y = y
	self.z = z
	self.vector_location = V{self.x, self.y, self.z}
	self.distance = distance
	self.description = description
	self.keep_running = keep_running
	self.dispose_bag = DisposeBag.new()
 	return self
end

function RunToLocationAction:destroy()
	self.dispose_bag:destroy()
	Action.destroy(self)
end

function RunToLocationAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	-- if we're already there, return false
	local dist = self:target_distance()
	if dist < self.distance then
		return false
	end

	return true
end

function RunToLocationAction:perform()
	if self:is_cancelled() then
		windower.ffxi.run(false)
		self:complete(false)
		return
	end

	if windower.ffxi.get_player().target_locked then
		windower.send_command('input /lockon')
	end
	windower.ffxi.follow()

	local player_pos = player_util.get_player_position()
	windower.ffxi.run(self.x - player_pos[1], self.y - player_pos[2], self.z)

	local prerender = Renderer.shared():onPrerender()
	self.dispose_bag:add(prerender:addAction(function()
		if self:is_cancelled() then
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

		local dist = self:target_distance()
		if dist < self.distance then
			if not self.keep_running then
				windower.ffxi.run(false)
			end
			self:complete(true)
			return
		end

		local player_pos = player_util.get_player_position()
		windower.ffxi.run(self.x - player_pos[1], self.y - player_pos[2], self.z)
	end), prerender)
end

function RunToLocationAction:target_distance()
	local player_pos = player_util.get_player_position()
	return player_util.distance(player_pos, self.vector_location)
end

function RunToLocationAction:get_max_duration()
    return 10
end

function RunToLocationAction:gettype()
	return "runtolocationaction"
end

function RunToLocationAction:getrawdata()
	local res = {}

	res.runtolocationaction = {}
	res.runtolocationaction.x = self.x
	res.runtolocationaction.y = self.y
	res.runtolocationaction.z = self.z

	return res
end

function RunToLocationAction:copy()
	return RunToLocationAction.new(self.x, self.y, self.z)
end

function RunToLocationAction:tostring()
    return self.description or ("Run to Location: (%d, %d)"):format(self.x, self.y)
end

return RunToLocationAction



