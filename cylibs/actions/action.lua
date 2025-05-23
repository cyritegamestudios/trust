---------------------------
-- Action base class.
-- @class module
-- @name Action

require('tables')
require('logger')
require('vectors')

local Event = require('cylibs/events/Luvent')

local Action = {}
Action.__index = Action

-- Event called when the action completes
function Action:on_action_complete()
    return self.action_complete
end

---- A cache of party member buffs.
-- @table ActionPriority
-- @tfield number default Default priority
-- @tfield number medium Medium priority
-- @tfield number high High priority
-- @tfield number highest Highest priority
ActionPriority = {}
ActionPriority.low = 0
ActionPriority.default = 1
ActionPriority.medium = 2
ActionPriority.high = 3
ActionPriority.highest = 999

actions_created = 0
actions_destroyed = 0
actions_counter = {}

-------
-- Default initializer for an action.
-- @tparam number x X coordinate of action
-- @tparam number y Y coordinate of action
-- @tparam number z Z coordinate of action
-- @treturn Action An action
function Action.new(x, y, z, target_index, conditions)
    local self = setmetatable({
        x = x;
        y = y;
        z = z;
        target_index = target_index or windower.ffxi.get_player().index;
        conditions = conditions or L{};
        cancelled = false;
        priority = ActionPriority.default;
        identifier = os.time();
    }, Action)

    self.action_complete = Event.newEvent()

    actions_created = actions_created + 1

    return self
end

function Action:destroy()
    if self.is_destroyed then
        return
    end
    self.is_destroyed = true

    actions_destroyed = actions_destroyed + 1

    self:on_action_complete():removeAllActions()
end

function Action:can_perform()
    if self:is_cancelled() then
        return false
    end
    for condition in self.conditions:it() do
        local check_target_index = condition:get_target_index() or self.target_index
        if not condition:is_satisfied(check_target_index) then
            logger.notice(self.__class, 'can_perform', 'failed condition', condition:tostring())
            return false
        end
    end
    return true
end

function Action:perform()
end

function Action:complete(success)
    if self.completed then
        return
    end
    self.completed = true

    self:on_action_complete():trigger(self, success)
end

function Action:cancel()
    self.cancelled = true

    self:complete(false)
end

function Action:get_position()
    local v = vector.zero(3)

    v[1] = self.x
    v[2] = self.y
    v[3] = self.z

    return v
end

function Action:get_target_index()
    return self.target_index
end

function Action:gettype()
    return "action"
end

function Action:getpriority()
    return self.priority
end

function Action:getrawdata()
    local res = {}

    res.action = {}
    res.action.x = self.x
    res.action.y = self.y
    res.action.z = self.z

    return res
end

function Action:is_cancelled()
    return self.cancelled
end

function Action:is_completed()
    return self.completed
end

function Action:getidentifier()
    return self.identifier
end

function Action:set_action_queue_id(action_queue_id)
    self.action_queue_id = action_queue_id
end

function Action:get_action_queue_id()
    return self.action_queue_id
end

function Action:copy()
    return Action.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function Action:is_equal(action)
    return self.identifier == action:getidentifier()
end

function Action:tostring()
    return "Action %d, %d":format(self:get_position()[1], self:get_position()[2])
end

function Action:get_max_duration()
    return 5
end

function Action:set_start_time(time_in_sec)
    self.start_time = time_in_sec
end

function Action:get_start_time()
    return self.start_time
end

function Action:add_condition(condition)
    if not self.conditions:contains(condition) then
        self.conditions:append(condition)
    end
end

function Action:on_incoming_chunk(id, data, modified, injected, blocked)
    return false
end

function Action:on_outgoing_chunk(id, data, modified, injected, blocked)
    return false
end

function Action:debug_log_create(action_type)
    if self.logged_create then
        return
    end
    self.logged_create = true
    if actions_counter[action_type] == nil then
        actions_counter[action_type] = 0
    end
    actions_counter[action_type] = actions_counter[action_type] + 1
end

function Action:debug_log_destroy(action_type)
    if self.logged_destroy then
        return
    end
    self.logged_destroy = true
    if actions_counter[action_type] then
        actions_counter[action_type] = actions_counter[action_type] - 1
    end
end

function Action:gettargetindex()
    return self.target_index
end

return Action



