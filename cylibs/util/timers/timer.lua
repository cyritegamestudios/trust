local Event = require('cylibs/events/Luvent')
local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')

local Timer = {}
Timer.__index = Timer
Timer.__type = "Timer"

---
-- Event triggered every time the timer fires.
--
function Timer:onTimeChange()
    return self.timeChange
end

---
-- Creates a new Timer that fires on an interval.
-- @tparam number timeInterval The interval on which to fire the timer
-- @tparam number width The width of the image.
-- @tparam number height The height of the image.
-- @treturn ImageItem The newly created ImageItem.
--
function Timer.scheduledTimer(timeInterval, delay)
    local self = setmetatable({}, Timer)

    self.timeInterval = timeInterval
    self.delay = delay or 0
    self.running = false
    self.lastTime = os.clock()
    self.timeChange = Event.newEvent()
    self.disposeBag = DisposeBag.new()

    return self
end

function Timer:destroy()
    self:cancel()

    self.timeChange:removeAllActions()

    self.disposeBag:destroy()
end

---
-- Starts the timer if it's not already running.
--
function Timer:start()
    if self:isRunning() then
        return
    end
    self.running = true

    self.lastTime = os.clock() + self.delay

    self.disposeBag:add(Renderer.shared():onPrerender():addAction(function()
        if not self.paused and self.running and os.clock() - self.lastTime >= self.timeInterval then
            self.lastTime = os.clock()
            self:onTimeChange():trigger(self)
        end
    end), Renderer.shared():onPrerender())
end

function Timer:resume()
    self.paused = false
    if not self:isRunning() then
        self:start()
    end
end

function Timer:pause()
    self.paused = true
end

---
-- Cancels the timer if it's running.
--
function Timer:cancel()
    if not self:isRunning() then
        return
    end
    self.running = false

    self.disposeBag:dispose()
end

---
-- Returns whether the timer is running.
-- @treturn boolean True if the timer is running.
--
function Timer:isRunning()
    return self.running
end

---
-- Checks if this Timer is equal to another.
-- @tparam Timer otherItem The other Timer to compare with.
-- @treturn boolean True if the Timers are equal, false otherwise.
--
function Timer:__eq(otherItem)
    return self.timeInterval == otherItem.timeInterval
end

return Timer