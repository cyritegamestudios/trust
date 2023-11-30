require('vectors')
require('math')
require('logger')

local Action = require('cylibs/actions/action')
local RunBehindAction = setmetatable({}, {__index = Action })
RunBehindAction.__index = RunBehindAction

function RunBehindAction.new(target_index)
	local self = setmetatable(Action.new(0, 0, 0), RunBehindAction)
	self.user_events = {}
	self.target_index = target_index
	self.distance = 3
 	return self
end

function RunBehindAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local target = windower.ffxi.get_mob_by_index(self.target_index)
	if not target or target.hpp <= 0 then
		return false
	end

	local player = windower.ffxi.get_player()
	if not player or player.status ~= 1 then return false end

	return true
end

function RunBehindAction:perform()
	self:run_behind(0)
end

function RunBehindAction:run_behind(retry_count)
	if self:is_cancelled() then
		windower.ffxi.run(false)
		return
	end

	if retry_count > 100 then
		windower.send_command('setkey numpad4 up')
		windower.send_command('setkey numpad6 up')
		self:complete(false)
		return
	end

	local direction = geometry_util.target_direction(windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id))
	local target_direction = geometry_util.target_direction(windower.ffxi.get_mob_by_index(self.target_index))

	local delta_direction = direction - target_direction
	if delta_direction < -0.2 then
		windower.send_command('setkey numpad6 down')
		windower.send_command('setkey numpad4 up')
	elseif delta_direction > 0.2 then
		windower.send_command('setkey numpad4 down')
		windower.send_command('setkey numpad6 up')
	else
		windower.send_command('setkey numpad4 up')
		windower.send_command('setkey numpad6 up')

		self:complete(true)
		return
	end

	coroutine.schedule(function()
		self:run_behind(retry_count + 1)
	end, 0.2)

	--[[local target = windower.ffxi.get_mob_by_index(self.target_index)

	if geometry_util.is_behind(target) then
		self:complete(true)
		return
	end

	local target_pos = geometry_util.get_point_behind_mob(target)
	print('running to x: '..target_pos[1]..' y: '..target_pos[2])
	--print('mob at x: '..target.x..' y: '..target.y)

	local dist = ffxi_util.distance(ffxi_util.get_player_position(), target_pos)
	if dist < self.distance then
		windower.ffxi.run(false) 
		self:complete(true)
	else
		local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

		local angle = (math.atan2((target_pos[2] - player.y), (target_pos[1] - player.x))*180/math.pi)*-1
		windower.ffxi.run((angle):radian())

		coroutine.schedule(function()
			self:run_behind(retry_count + 1)
		end, 0.1)
	end]]
end

function RunBehindAction:gettype()
	return "runbehindaction"
end

function RunBehindAction:getrawdata()
	local res = {}
	
	res.runbehindaction = {}
	res.runbehindaction.x = self.x
	res.runbehindaction.y = self.y
	res.runbehindaction.z = self.z
	
	return res
end

function RunBehindAction:copy()
	return RunBehindAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function RunBehindAction:is_equal(action)
	if action == nil then return false end
	return self:gettype() == action:gettype()
end

function RunBehindAction:tostring()
    return "RunBehindAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return RunBehindAction



