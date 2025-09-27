---------------------------
-- Action representing the player running to a target.
-- @class module
-- @name RunToAction

local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')

local Action = require('cylibs/actions/action')
local RunToAction = setmetatable({}, {__index = Action })
RunToAction.__index = RunToAction

function RunToAction.new(target_index, distance, force_perform)
	local self = setmetatable(Action.new(0, 0, 0), RunToAction)
	self.dispose_bag = DisposeBag.new()
	self.user_events = {}
	self.target_index = target_index
	self.distance = distance
	self.force_perform = force_perform
	self.was_locked_on = false
	return self
end

function RunToAction:destroy()
	Action.destroy(self)

	self.dispose_bag:destroy()
end

function RunToAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	return true
end

function RunToAction:perform()
	if windower.ffxi.get_player().target_locked then
		windower.send_command('input /lockon')
		self.was_locked_on = true
	end

	self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
		local target = windower.ffxi.get_mob_by_index(self.target_index)

		if self:is_cancelled() or target == nil then
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

		local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

		local angle = (math.atan2((target.y - player.y), (target.x - player.x))*180/math.pi)*-1

		windower.ffxi.follow()
		windower.ffxi.run((angle):radian())

		local adjusted_distance = self.distance --+ player.model_size + target.model_size - 0.2
		if target.distance:sqrt() < adjusted_distance then
			windower.ffxi.run(false)
			if self.was_locked_on then
				windower.send_command('input /lockon')
			end
			self:complete(true)
		end
	end), Renderer.shared():onPrerender())
end

function RunToAction:gettype()
	return "runtoaction"
end

function RunToAction:getrawdata()
	local res = {}

	res.runtoaction = {}
	res.runtoaction.x = self.x
	res.runtoaction.y = self.y
	res.runtoaction.z = self.z

	return res
end

function RunToAction:copy()
	return RunToAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function RunToAction:tostring()
	return "Run To"
	--return string.format("Run to %d yalms", self.distance)
end

return RunToAction



