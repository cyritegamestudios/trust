require('vectors')
require('math')
require('logger')

local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')

local Action = require('cylibs/actions/action')
local RunAway = setmetatable({}, {__index = Action })
RunAway.__index = RunAway

function RunAway.new(target_index, distance)
	local self = setmetatable(Action.new(0, 0, 0), RunAway)
	self.dispose_bag = DisposeBag.new()
	self.user_events = {}
	self.target_index = target_index
	self.distance = distance
	self.backpedal = false
	self.back_key_down = false
	self.lock_frames = 0
 	return self
end

-- Releases the back key if a backpedal is in progress. Called on every
-- exit path so the key can never be left held down.
function RunAway:stop_backpedal()
	if self.back_key_down then
		windower.send_command('setkey numpad2 up')
		self.back_key_down = false
	end
end

function RunAway:destroy()
	Action.destroy(self)

	self:stop_backpedal()
	windower.ffxi.run(false)

	self.dispose_bag:destroy()
end

function RunAway:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	return true
end

function RunAway:perform()
	local player = windower.ffxi.get_player()
	local target = windower.ffxi.get_mob_by_index(self.target_index)

	-- Back up instead of turning around when the situation allows it:
	-- the player is engaged with the target and only a short distance
	-- has to be gained (the combat distance-keeping case). Backing up
	-- holds the back key (numpad2) with lock-on engaged, so the player
	-- keeps facing the target while gaining distance -- the same key
	-- approach RunBehindAction uses for strafing. Longer gains and any
	-- use while disengaged keep the original turn-and-run behaviour.
	self.backpedal = false
	if player.status == 1 and target and target.distance then
		if self.distance - target.distance:sqrt() <= 3 then
			self.backpedal = true
		end
	end

	if self.backpedal then
		if not player.target_locked then
			windower.send_command('input /lockon')
		end
	elseif player.target_locked then
		windower.send_command('input /lockon')
		self.was_locked_on = true
	end

	self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
		local target = windower.ffxi.get_mob_by_index(self.target_index)

		if self:is_cancelled() or target == nil then
			self:stop_backpedal()
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

		local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
		local angle = (math.atan2((target.y - player.y), (target.x - player.x))*180/math.pi)*-1

		if self.backpedal and windower.ffxi.get_player().status ~= 1 then
			-- Disengaged mid-backpedal: nothing to back away from.
			self:stop_backpedal()
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

		if self.backpedal and windower.ffxi.get_player().target_locked then
			-- Locked on, so facing stays on the target: just hold the
			-- back key. Autorun-style movement must stay off.
			windower.ffxi.run(false)
			if not self.back_key_down then
				windower.send_command('setkey numpad2 down')
				self.back_key_down = true
			end
		elseif self.backpedal and self.lock_frames < 15 then
			-- Lock-on was just requested and has not taken effect yet:
			-- wait a few frames rather than start turning around.
			self.lock_frames = self.lock_frames + 1
		else
			self:stop_backpedal()
			windower.ffxi.follow()
			windower.ffxi.run((angle+180):radian())
		end

		local adjusted_distance = self.distance --+ player.model_size + target.model_size - 0.2
		if target.distance:sqrt() > adjusted_distance then
			self:stop_backpedal()
			windower.ffxi.run(false)
			if self.was_locked_on then
				windower.send_command('input /lockon')
			end
			self:complete(true)
		end
	end), Renderer.shared():onPrerender())
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
	return "Run Away"
end

return RunAway



