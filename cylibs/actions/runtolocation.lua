---------------------------
-- Action representing the player running to a location.
-- @class module
-- @name RunToLocationAction

require('vectors')
require('math')
require('logger')

local player_util = require('cylibs/util/player_util')
local Action = require('cylibs/actions/action')
local RunToLocationAction = setmetatable({}, {__index = Action })
RunToLocationAction.__index = RunToLocationAction

function RunToLocationAction.new(x, y, z, distance, description)
	local self = setmetatable(Action.new(0, 0, 0), RunToLocationAction)
	self.user_events = {}
	self.x = x
	self.y = y
	self.z = z
	self.vector_location = V{self.x, self.y, self.z}
	self.distance = distance
	self.description = description
 	return self
end

function RunToLocationAction:can_perform()
	if self:is_cancelled() then
		self:complete(false)
		return false
	end

	-- If crafting, return false
	-- TODO(Aldros): Should add other states, maybe a can_move() fn
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
	-- TODO(Aldros): We should externalize unlock if locked on
	if windower.ffxi.get_player().target_locked then
		windower.send_command('input /lockon')
	end
	self:run_to(self.distance, 0)
end

function RunToLocationAction:complete(success)
	Action.complete(self, success)
end

function RunToLocationAction:run_to(distance, retry_count)
	if self:is_cancelled() then
		windower.ffxi.run(false)
		return
	end
	windower.ffxi.follow()

	if retry_count > 100 then -- retry count * walk_interval gives total timeout for the action, in this case 10s without progress
		self:complete(false)
		return
	end

	local dist = self:target_distance()
	if dist < self.distance then -- If we're within 'distance' of target, then we're done
		windower.ffxi.run(false)
		self:complete(true)
	else
		if self:is_cancelled() then
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

		-- Get target direction to run in
		local player_pos = player_util.get_player_position()
		windower.ffxi.run(self.x - player_pos[1], self.y - player_pos[2], self.z)

		local walk_interval = 0.1 -- Update walk every 0.1s

		coroutine.schedule(function()
			self:run_to(self.distance, retry_count + 1)
		end, walk_interval)
	end
end

-- Gets the delta between the distance to the target and
-- the requested distance from the target
function RunToLocationAction:delta_distance()
	return math.abs(self:target_distance() - self.distance)
end

-- Gets the distance from current player location to the target location
function RunToLocationAction:target_distance()
	local player_pos = player_util.get_player_position()

	return player_util.distance(player_pos, self.vector_location)
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



