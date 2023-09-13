local Frame = require('cylibs/ui/views/frame')
local View = require('cylibs/ui/views/view')

require('queues')

local ScrollView = setmetatable({}, {__index = View })
ScrollView.__index = ScrollView


function ScrollView.new(frame)
    local self = setmetatable(View.new(frame), ScrollView)

    self.contentView = View.new(frame)
    self.contentOffset = Frame.new(0, 0, 0, 0)
    self.scrollEnabled = false

    self:addSubview(self.contentView)

    return self
end

---
-- Get the content view of the ScrollView.
-- @treturn View The content view of the ScrollView.
--
function ScrollView:getContentView()
    return self.contentView
end

---
-- Set a new content view for the ScrollView.
-- @tparam View newContentView The new content view for the ScrollView.
--
function ScrollView:setContentView(newContentView)
    self.contentView = newContentView
end

---
-- Get the content offset of the ScrollView.
-- @treturn Frame The content offset of the ScrollView.
--
function ScrollView:getContentOffset()
    return self.contentOffset
end

---
-- Set a new content offset for the ScrollView.
-- @tparam number contentOffsetX The new content offset along the x-axis.
-- @tparam number contentOffsetY The new content offset along the y-axis.
--
function ScrollView:setContentOffset(contentOffsetX, contentOffsetY)
    self.contentOffset.x = contentOffsetX
    self.contentOffset.y = contentOffsetY

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Checks whether scrolling is enabled for the ScrollView.
-- @treturn boolean True if scrolling is enabled, false otherwise.
--
function ScrollView:isScrollEnabled()
    return self.scrollEnabled
end

---
-- Sets whether scrolling is enabled for the ScrollView.
-- @tparam boolean scrollEnabled True to enable scrolling, false to disable.
--
function ScrollView:setScrollEnabled(scrollEnabled)
    self.scrollEnabled = scrollEnabled
end

function ScrollView:layoutIfNeeded()
    if not View.layoutIfNeeded(self) or self.contentView == nil then
        return
    end

    self.contentView.frame = Frame.new(self.contentOffset.x, self.contentOffset.y, self.frame.width, self.frame.height)
    self.contentView:setVisible(self:isVisible())

    self.contentView:setNeedsLayout()
    self.contentView:layoutIfNeeded()

    self:updateContentView()
end

---
-- Updates the content view by managing visibility based on clipping and scrollability.
-- If scrolling is disabled, this function does nothing.
--
function ScrollView:updateContentView()
    if not self:isScrollEnabled() or not self:isVisible() then
        return
    end
    local subviews = Q{ self }
    while not subviews:empty() do
        local view = subviews:pop()
        for _, subview in pairs(view.subviews) do
            subviews:push(subview)
        end
        if self:shouldClipToBounds(view) then
            view:setVisible(false)
        else
            view:setVisible(true)
        end
    end
end

---
-- Determines whether the provided view should clip its content to its bounds within the ScrollView.
-- @tparam View view The view to evaluate for clipping.
-- @treturn boolean True if the view should clip its content, false otherwise.
--
function ScrollView:shouldClipToBounds(view)
    local absolutePosition = self:getAbsolutePosition()
    local viewAbsolutePosition = view:getAbsolutePosition()

    if view:getClipsToBounds() then
        if (viewAbsolutePosition.y < absolutePosition.y or viewAbsolutePosition.y + view.frame.height > absolutePosition.y + self.frame.height)
                or (viewAbsolutePosition.x < absolutePosition.x or viewAbsolutePosition.x + view.frame.width > absolutePosition.x + self.frame.width) then
            return true
        else
            return false
        end
    end
end

return ScrollView