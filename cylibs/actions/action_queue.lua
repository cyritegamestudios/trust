---------------------------
-- Action queue to execute Actions.
-- @class module
-- @name ActionQueue

require('tables')
require('logger')
require('vectors')
require('queues')

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local RangedAttackAction = require('cylibs/actions/ranged_attack')
local Timer = require('cylibs/util/timers/timer')

local Action = require('cylibs/actions/action')

local ActionQueue = {}
ActionQueue.__index = ActionQueue

ActionQueue.Mode = {}
ActionQueue.Mode.Default = "default"

ActionQueue.empty = Event.newEvent()

-- Event called when an action starts.
function ActionQueue:on_action_start()
	return self.action_start
end

-- Event called when an action ends.
function ActionQueue:on_action_end()
	return self.action_end
end

-- Event called when an action is added to the queue.
function ActionQueue:on_action_queued()
	return self.action_queued
end

function ActionQueue.new(completion, is_priority_queue, max_size, debugging_enabled, verbose, calculate_forced_delay)
	local self = setmetatable({
		current_action = nil;
	}, ActionQueue)

	self.queue = Q{}
	self.is_priority_queue = is_priority_queue
	self.max_size = max_size or 9999
	self.is_enabled = true
	self.completion = completion
	self.debugging_enabled = debugging_enabled
	self.verbose = verbose
	self.identifier = os.time()
	self.forced_delay_time = os.clock()
	self.mode = ActionQueue.Mode.Default
	self.dispose_bag = DisposeBag.new()
	self.action_start = Event.newEvent()
	self.action_end = Event.newEvent()
	self.action_queued = Event.newEvent()

	if calculate_forced_delay then
		local category_to_action_type = {
			[2] = RangedAttackAction.__type,
			[3] = WeaponSkillAction.__type,
			[4] = SpellAction.__type,
			[6] = JobAbilityAction.__type,
			[8] = SpellAction.__type,
		}
		self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
			if action.actor_id ~= windower.ffxi.get_player().id then
				return
			end
			if L{ 2, 3, 6 }:contains(action.category) then
				self.forced_delay_time = os.clock() + 2
			elseif action.category == 4 or action.category == 8 and action.param == 28787 then
				self.forced_delay_time = os.clock() + 3
			end
			if category_to_action_type[action.category] then
				self.last_action_type = category_to_action_type[action.category]
			end
		end), WindowerEvents.Action)
	end

	self.timer = Timer.scheduledTimer(5)
	self.timer:onTimeChange():addAction(function(_)
		self:cleanup()
	end)


	self.dispose_bag:addAny(L{ self.timer })

	return self
end

function ActionQueue:destroy()
	Action.action_complete:removeAction(self.action_complete_id)

	self:on_action_start():removeAllActions()
	self:on_action_end():removeAllActions()
	self:on_action_queued():removeAllActions()

	self.dispose_bag:destroy()
end

function ActionQueue:get_forced_delay(action)
	local forced_delay = self.forced_delay_time - os.clock()
	if forced_delay > 0 then
		local action_type = action.__type
		if action_type == SequenceAction.__type and action.queue and action.queue:length() > 0 then
			action_type = action.queue[1].__type
		end
		if L{ JobAbilityAction.__type, SpellAction.__type, WeaponSkillAction.__type }:contains(action_type) then
			return forced_delay
		elseif action_type == RangedAttackAction.__type then
			--if self.last_action_type ~= RangedAttackAction.__type then
			--	return forced_delay
			--end
		end
	end
	return 0
end

-- Performs the next action in the queue if the
-- queue is not empty
function ActionQueue:perform_next_action()
	if self.current_action ~= nil then
		return
	end
	
	if self.queue:empty() then
		ActionQueue.empty:trigger(self)
		return
	end

	local next_action = self.queue:pop()
	if next_action ~= nil and next_action:can_perform() then
		local forced_delay = self:get_forced_delay(next_action)
		if forced_delay > 0 then
			local display_name = next_action.display_name
			next_action = SequenceAction.new(L{
				WaitAction.new(0, 0, 0, forced_delay),
				next_action,
			}, next_action:getidentifier())
			next_action.display_name = display_name
		end

		next_action:set_action_queue_id(self.identifier)
		if self.debugging_enabled then
			print(tostring(self.identifier)..' '..next_action:gettype()..' '..(next_action:getidentifier() or 'nil')..' start')
			windower.chat.input('// lua m')
		end
		self.current_action = next_action

		self:on_action_start():trigger(self, next_action)

		self.current_action:on_action_complete():addAction(function(a, success) self:handle_action_completed(a, success) end)
		self.current_action:set_start_time(os.time())
		self.current_action:perform()
	else
		if next_action ~= nil then
			next_action:destroy()
		end
		self:perform_next_action()
	end
end

function ActionQueue:handle_action_completed(a, success)
	self.current_action:destroy()
	self.current_action = nil

	if self.debugging_enabled then
		print('actions created: '..actions_created..' actions destroyed: '..actions_destroyed)

		print(a:gettype()..' '..(a:getidentifier() or 'nil')..' end, success: '..tostring(success))
		windower.chat.input('// lua m')
	end
	--print(a:gettype()..' '..(a:getidentifier() or 'nil')..' end, success: '..tostring(success))

	self:on_action_end():trigger(a, success)

	self:perform_next_action()
end

-- Pushes the given action onto the queue
function ActionQueue:push_action(action, check_duplicates)
	self:cleanup()

	if not self.is_enabled or (check_duplicates and check_duplicates == true and self:contains(action)) or self:length() >= self.max_size then
		action:destroy()
		return
	end

	self.queue:push(action)

	if self.is_priority_queue and self.queue:length() > 1 then
		self.queue:sort(function (action1, action2)
			if action1 == nil then
				return false
			end
			if action2 == nil then
				return false
			end
			return action1:getpriority() > action2:getpriority()
		end)
	end

	if self.current_action == nil then
		self:perform_next_action()
	else
		self:on_action_queued():trigger(self)
	end
end

-- Pushes the given actions onto the queue
function ActionQueue:push_actions(actions, check_duplicates)
	if not self.is_enabled or (self:length() + actions:length()) >= self.max_size then
		for action in actions:it() do
			action:destroy()
		end
		return
	end

	if check_duplicates then
		actions = L(actions:filter(function(a) return not self:contains(a) end))
	end

	if actions:length() == 0 then
		return
	end

	for action in actions:it() do
		self.queue:push(action)
	end

	if self.is_priority_queue and self.queue:length() > 1 then
		self.queue:sort(function (action1, action2)
			if action1 == nil then
				return false
			end
			if action2 == nil then
				return false
			end
			return action2 == nil or action1:getpriority() > action2:getpriority()
		end)
	end
	if self.current_action == nil then
		self:perform_next_action()
	else
		self:on_action_queued():trigger(self)
	end
end

-- Returns true if the queue is empty
function ActionQueue:is_empty()
	return self.queue:empty()
end

-- Returns true if the queue alrady contains a matching action
function ActionQueue:contains(action)
	for a in self.queue:it() do
		if a:is_equal(action) then return true end
	end
	if self.current_action and action:is_equal(self.current_action) then
		return true
	end
	return false
end

-- Returns true if the queue already contains an action matching the given type
function ActionQueue:contains_action_of_type(action_type)
	for a in self.queue:it() do
		if a:gettype() == action_type then return true end
	end
	return false
end

-- Returns the last element in the queue, without removing it
function ActionQueue:last()
	if self.queue:empty() then
		return nil
	end
	return self.queue[self:length()-1]
end

-- Returns the number of actions in the queue
function ActionQueue:length()
	return self.queue:length()
end

-- Clears all actions if the current action has been executing for too long
function ActionQueue:cleanup()
	if self.current_action ~= nil and self.current_action:get_start_time() then
		if (os.time() - self.current_action:get_start_time()) > self.current_action:get_max_duration() then
			if self.debugging_enabled then
				print('clearing stale actions becasee '..self.current_action:gettype()..'_'..self.current_action:getidentifier())
			end
			self:clear()
		end
	end
end

-- Clears all actions in the queue
function ActionQueue:clear()
	if self.current_action ~= nil then
		self.current_action:cancel()
	end

	for action in self.queue:it() do
		action:destroy()
	end
	self.queue:clear()
end

function ActionQueue:set_enabled(is_enabled)
	is_enabled = is_enabled and windower.ffxi.get_player() and not L{ 2, 3 }:contains(windower.ffxi.get_player().status)
	if is_enabled then
		self:enable()
	else
		self:disable()
	end
end

-------
-- Enables the action queue.
function ActionQueue:enable()
	self.is_enabled = true
	self.timer:start()
end

-------
-- Disables the action queue. All queued actions will be cleared and new actions added with push_action will
-- be ignored.
function ActionQueue:disable()
	if self.is_enabled == false then
		return
	end
	self.is_enabled = false
	self:clear()
end

---
-- Sets the mode of the ActionQueue object.
--
-- This function allows you to set the operating mode for the ActionQueue.
--
-- @tparam ActionQueue.Mode mode The mode to set. Should be ActionQueue.Mode.Default.
-- @see ActionQueue.Mode
--
function ActionQueue:set_mode(mode)
	if not L{ ActionQueue.Mode.Default }:contains(mode) then
		mode = ActionQueue.Mode.default
	end
	if self.mode == mode then
		return
	end
	self.mode = mode
end

---
-- Gets the current operating mode of the ActionQueue object.
--
-- @treturn ActionQueue.Mode Returns the current mode, which can be ActionQueue.Mode.Default.
-- @see ActionQueue.Mode
--
function ActionQueue:get_mode()
	return self.mode
end

-- Debug functions

-------
-- Returns the list of actions in the queue.
-- @treturn L List of actions
--
function ActionQueue:get_actions()
	local actions = L{}
	if self.current_action then
		actions:append(self.current_action)
	end
	for action in self.queue:it() do
		actions:append(action)
	end
	return actions
end

function ActionQueue:has_action(identifier)
	local current_actions = self:get_actions()
	for action in current_actions:it() do
		if action:getidentifier() == identifier then
			return true
		end
	end
	return false
end

return ActionQueue



