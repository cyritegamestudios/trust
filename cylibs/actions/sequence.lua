local Action = require('cylibs/actions/action')
local SequenceAction = setmetatable({}, {__index = Action })
SequenceAction.__index = SequenceAction

function SequenceAction.new(actions, identifier)
	local self = setmetatable(Action.new(0, 0, 0), SequenceAction)
  	self.queue = Q{}
	self.max_duration = 0
	for action in actions:it() do
		self.queue:push(action)
		self.max_duration = self.max_duration + action:get_max_duration()
	end
	self.max_duration = 5
	self.identifier = identifier or os.time()

	self:debug_log_create(self:gettype())

  	return self
end

function SequenceAction:destroy()
	for action in self.queue:it() do
		action:destroy()
	end

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function SequenceAction:can_perform()
	for action in self.queue:it() do
		if not action:can_perform() then
			return false
		end
	end
	return true
end

function SequenceAction:perform()
	if self:is_cancelled() then
		self:complete(false)
		return
	end

	if self.queue:length() > 0 then
		local next_action = self.queue:pop()
		next_action:on_action_complete():addAction(function(a, success)
			a:destroy()
			self:perform()
		end)
		next_action:set_start_time(os.time())
		next_action:perform()
	else
		self:complete(true)
	end
end

function SequenceAction:cancel()
	for action in self.queue:it() do
		action:cancel()
		action:destroy()
	end

	Action.cancel(self)
end

function SequenceAction:getactions()
	return self.actions
end

function SequenceAction:gettype()
	return "sequenceaction"
end

function SequenceAction:getidentifier()
	return self.identifier
end

function SequenceAction:getrawdata()
	local res = {}
	
	res.sequenceaction = {}
	res.sequenceaction.x = self.x
	res.sequenceaction.y = self.y
	res.sequenceaction.z = self.z
	res.sequenceaction.duration = self:get_duration()
	
	return res
end

function SequenceAction:is_equal(action)
	if action == nil then return false end
	return self:gettype() == action:gettype()
			and self:getidentifier() == action:getidentifier()
end

function SequenceAction:copy()
	return SequenceAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_duration())
end

function SequenceAction:tostring()
  return "SequenceAction delay: %d":format(self:get_duration())
end

function SequenceAction:get_max_duration()
	return self.max_duration
end

return SequenceAction




