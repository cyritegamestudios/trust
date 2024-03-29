require('vectors')
require('math')
require('logger')

local PlayerUtil = require('cylibs/util/player_util')
local serializer_util = require('cylibs/util/serializer_util')

local Action = require('cylibs/actions/action')
local WalkAction = setmetatable({}, {__index = Action })
WalkAction.__index = WalkAction

function WalkAction.new(x, y, z, min_dist)
	local self = setmetatable(Action.new(x, y, z), WalkAction)
	self.min_dist = min_dist or 2
 	return self
end

function WalkAction:destroy()
	Action.destroy(self)

	windower.ffxi.run(false)
end

function WalkAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	local dist = PlayerUtil.distance(PlayerUtil.get_player_position(), self:get_position())

	if --[[dist < self.min_dist or]] dist > 500 then
		return false
	end
	
	return true
end

function WalkAction:perform()
	self:walk_to_point(self:get_position(), 0)
end

function WalkAction:walk_to_point(v, retry_count)
	if self:is_cancelled() then
		return
	end
	
	windower.ffxi.follow()

	if retry_count > 20 then
		windower.ffxi.run(false)
		self:complete(false)
		return
	end

	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

	local p = vector.zero(3)

	p[1] = player.x
	p[2] = player.y
	p[3] = player.z

	local dist = math.sqrt((p[1]-v[1])^2+(p[2]-v[2])^2+(p[3]-v[3])^2)

	if dist < self.min_dist then
		windower.ffxi.run(false) 
		self:complete(true)
	else
		if self:is_cancelled() then
			windower.ffxi.run(false)
			return
		end
		
		local x = v[1]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).x
		local y = v[2]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).y
		local h = math.atan2(x, y)

		local direction = h - 1.5708

		windower.ffxi.run(direction)

		local walk_speed = 10
		local walk_time = dist / walk_speed

		coroutine.schedule(function()
			self:walk_to_point(v, retry_count + 1)
		end, walk_time)
	end
end

function WalkAction:distance(x, y, z)
	return math.sqrt((self.x-x)^2+(self.y-y)^2+(self.z-z)^2)
end

function WalkAction:gettype()
	return "walkaction"
end

function WalkAction:getrawdata()
	local res = {}
	
	res.walkaction = {}
	res.walkaction.x = self.x
	res.walkaction.y = self.y
	res.walkaction.z = self.z
	
	return res
end

function WalkAction:serialize()
	return "WalkAction.new(" .. serializer_util.serialize_args(self.x, self.y, self.z, self.min_dist) .. ")"
end

function WalkAction:copy()
	return WalkAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function WalkAction:tostring()
    return "WalkAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return WalkAction



