---------------------------
-- Action representing the player running to a target.
-- @class module
-- @name RunToAction

local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')

local Action = require('cylibs/actions/action')
local RunToAction = setmetatable({}, {__index = Action })
RunToAction.__index = RunToAction

-- Tracks whether the player is casting a song or spell, from the
-- same action-packet events CombatMode uses (Spell.Begin/Finish,
-- categories 8 and 4; an interrupted cast only shows as category 8
-- with param 28787). A RunTo steering while a cast is running
-- interrupts the cast, so a RunTo never starts mid-cast and one
-- already running cancels itself when a cast begins; whatever
-- wanted the position (CombatMode's walk-in, the puller) simply
-- asks again once the cast lands. Subscribed lazily on first use
-- so the events module is loaded by then.
local player_is_casting = false
local casting_tracker_started = false
local function start_casting_tracker()
	if casting_tracker_started then
		return
	end
	casting_tracker_started = true
	WindowerEvents.Spell.Begin:addAction(function(actor_id, _)
		local player = windower.ffxi.get_player()
		if player and actor_id == player.id then
			player_is_casting = true
		end
	end)
	WindowerEvents.Spell.Finish:addAction(function(actor_id, _, _)
		local player = windower.ffxi.get_player()
		if player and actor_id == player.id then
			player_is_casting = false
		end
	end)
	WindowerEvents.Action:addAction(function(act)
		local player = windower.ffxi.get_player()
		if player and act.actor_id == player.id and act.category == 8 and act.param == 28787 then
			player_is_casting = false
		end
	end)
	windower.register_event('zone change', function()
		player_is_casting = false
	end)
end

function RunToAction.new(target_index, distance, force_perform)
	start_casting_tracker()
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

	if player_is_casting then
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
		if player_is_casting then
			windower.ffxi.run(false)
			self:complete(false)
			return
		end

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



