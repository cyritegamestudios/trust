local Color = require('cylibs/ui/views/color')
local Event = require('cylibs/events/Luvent')
local Mouse = require('cylibs/ui/input/mouse')
local View = require('cylibs/ui/views/view')


local ScrollBar = setmetatable({}, {__index = View })
ScrollBar.__index = ScrollBar

---
-- Get the event triggered when the scroll bar is clicked to scroll back.
--
-- @treturn Event The scroll back click event.
--
function ScrollBar:onScrollBackClick()
    return self.scrollBackClick
end

---
-- Get the event triggered when the scroll bar is clicked to scroll forward.
--
-- @treturn Event The scroll forward click event.
--
function ScrollBar:onScrollForwardClick()
    return self.scrollForwardClick
end

---
-- Create a new ScrollBar instance with the given frame.
--
-- @tparam Frame frame The frame of the ScrollBar.
-- @treturn ScrollBar The created ScrollBar.
--
function ScrollBar.new(frame)
    local self = setmetatable(View.new(frame), ScrollBar)

    self.scrollBackClick = Event.newEvent()
    self.scrollForwardClick = Event.newEvent()
    self.clickEvents = L{ self.scrollBackClick, self.scrollForwardClick }

    self:setBackgroundColor(Color.white:withAlpha(75))

    self:getDisposeBag():add(Mouse.input():onClick():addAction(function(type, x, y, delta, blocked)
        if blocked or not self:isVisible() then
            return
        end
        if self:hitTest(x, y) then
            self:scrollBarClick(x, y)
        end
        return false
    end), Mouse.input():onClick())

    return self
end

---
-- Destroy the ScrollBar and clean up resources.
--
function ScrollBar:destroy()
    View.destroy(self)

    for event in self.clickEvents:it() do
        event:removeAllActions()
    end
end

---
-- Handle the click event on the scroll bar and trigger corresponding actions.
--
-- @tparam number x The x-coordinate of the click event.
-- @tparam number y The y-coordinate of the click event.
--
function ScrollBar:scrollBarClick(x, y)
    local absolutePosition = self:getAbsolutePosition()

    if self:getSize().width > self:getSize().height then
        if x > absolutePosition.x + self:getSize().width / 2 then
            self:onScrollForwardClick():trigger(self)
        else
            self:onScrollBackClick():trigger(self)
        end
    else
        if y > absolutePosition.y + self:getSize().height / 2 then
            self:onScrollForwardClick():trigger(self)
        else
            self:onScrollBackClick():trigger(self)
        end
    end
end

return ScrollBar