require('vectors')
require('math')
require('logger')

local PlayerUtil = require('cylibs/util/player_util')

local Action = require('cylibs/actions/action')
local RunAway = setmetatable({}, {__index = Action })
RunAway.__index = RunAway

function RunAway.new(target_index, distance)
	local self = setmetatable(Action.new(0, 0, 0), RunAway)
	self.user_events = {}
	self.target_index = target_index
	self.distance = distance
 	return self
end

function RunAway:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	local dist = self:delta_distance()
	if dist > self.distance then
		return false
	end

	return true
end

function RunAway:perform()
	--windower.send_command('input /lockon')
	self:run_to(self.distance, 0)
end

function RunAway:run_to(distance, retry_count)
	if self:is_cancelled() then
		return
	end
	
	windower.ffxi.follow()

	if retry_count > 100 then
		self:complete(false)
		return
	end

	local dist = self:target_distance()
	if dist > self.distance then
		windower.ffxi.run(false) 
		self:complete(true)
	else
		if self:is_cancelled() then
			windower.ffxi.run(false)
			return
		end

		local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
		local target = windower.ffxi.get_mob_by_index(self.target_index)

		local angle = (math.atan2((target.y - player.y), (target.x - player.x))*180/math.pi)*-1
		windower.ffxi.run((angle+180):radian())

		local walk_speed = 10
		local walk_time = 0.1--self:target_distance() / walk_speed

		coroutine.schedule(function()
			self:run_to(self.distance, retry_count + 1)
		end, walk_time)
	end
end

function RunAway:delta_distance()
	return math.abs(self:target_distance() - self.distance)
end

function RunAway:target_distance()
	local target = windower.ffxi.get_mob_by_index(self.target_index)
	if target == nil then
		return 0
	end

	return target.distance:sqrt()
end

function RunAway:gettype()
	return "runawayaction"
end

function RunAway:getrawdata()
	local res = {}
	
	res.runawayaction = {}
	res.runawayaction.x = self.x
	res.runawayaction.y = self.y
	res.runawayaction.z = self.z
	
	return res
end

function RunAway:copy()
	return RunAway.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function RunAway:tostring()
    return "RunAway: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return RunAway



