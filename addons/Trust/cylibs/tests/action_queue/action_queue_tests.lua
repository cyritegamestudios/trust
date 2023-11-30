local ActionQueue = require('cylibs/actions/action_queue')
local CyTest = require('cylibs/tests/cy_test')
local Event = require('cylibs/events/Luvent')
local TestAction = require('cylibs/tests/action_queue/test_action')

local ActionQueueTests = {}
ActionQueueTests.__index = ActionQueueTests

function ActionQueueTests:onCompleted()
    return self.completed
end

function ActionQueueTests.new()
    local self = setmetatable({}, ActionQueueTests)
    self.completed = Event.newEvent()
    return self
end

function ActionQueueTests:destroy()
    self.listView:destroy()

    self.completed:removeAllActions()
end

function ActionQueueTests:run()
    self:testQueue()
end

-- Tests

function ActionQueueTests:testQueue()
    local actionQueue = ActionQueue.new(nil, true, 5, false, true)

    actionQueue:push_action(TestAction.new("Action1", 1))
    actionQueue:push_action(TestAction.new("Action2", 1))
    actionQueue:push_action(TestAction.new("Action3", 1))

    CyTest.assertEqual(function() return actionQueue:get_actions():length() end, 2, "Unexpected size of queue")

    self:onCompleted():trigger(true)
end

return ActionQueueTests