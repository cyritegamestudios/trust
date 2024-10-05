local Color = require('cylibs/ui/views/color')
local Event = require('cylibs/events/Luvent')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
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
function ScrollBar.new(frame, backgroundImageItem)
    local self = setmetatable(View.new(frame), ScrollBar)

    self.scrollBackClick = Event.newEvent()
    self.scrollForwardClick = Event.newEvent()
    self.clickEvents = L{ self.scrollBackClick, self.scrollForwardClick }

    if backgroundImageItem then
        self:setBackgroundImageView(ImageCollectionViewCell.new(backgroundImageItem))
    else
        self:setBackgroundColor(Color.white:withAlpha(75))
    end

    self:setUserInteractionEnabled(true)
    self:setNeedsLayout()
    self:layoutIfNeeded()

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

---
-- Handle a mouse event.
--
-- @tparam number x The x-coordinate of the click event.
-- @tparam number y The y-coordinate of the click event.
--
function ScrollBar:onMouseEvent(type, x, y, delta)
    if type == Mouse.Event.Click then
        self.isClicking = true
        self:scrollBarClick(x, y)
        return true
    elseif type == Mouse.Event.Move then
        if self.isClicking then
            return true
        end
    elseif type == Mouse.Event.ClickRelease then
        if self.isClicking then
            self.isClicking = false
            return true
        end
    else
        self.isClicking = false
        return false
    end
    return false
end

return ScrollBar