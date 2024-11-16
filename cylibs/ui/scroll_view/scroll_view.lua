local Frame = require('cylibs/ui/views/frame')
local HorizontalScrollBar = require('cylibs/ui/scroll_view/horizontal_scroll_bar')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local ScrollBar = require('cylibs/ui/scroll_view/scroll_bar')
local VerticalScrollBar = require('cylibs/ui/scroll_view/vertical_scroll_bar')
local View = require('cylibs/ui/views/view')

require('queues')

local ScrollView = setmetatable({}, {__index = View })
ScrollView.__index = ScrollView
ScrollView.__type = "ScrollView"


function ScrollView.new(frame, style)
    local self = setmetatable(View.new(frame), ScrollView)

    self.style = style
    self.padding = Padding.equal(0)
    self.contentView = View.new(frame)
    self.contentSize = Frame.new(0, 0, frame.width, frame.height)
    self.contentOffset = Frame.zero()
    self.scrollEnabled = false
    self.scrollBarSize = 8
    self.scrollDelta = 10
    self.scrollBars = L{}
    self.scrollCooldown = 0.05
    self.lastScrollTime = os.clock()

    self:addSubview(self.contentView)

    return self
end

function ScrollView:createScrollBars()
    if not self.scrollBars:empty() then
        return
    end

    self.horizontalScrollBar = HorizontalScrollBar.new(Frame.zero(), self.style:getScrollTrackItem(), self.style:getScrollForwardItem(), self.style:getScrollBackItem())
    self.verticalScrollBar = VerticalScrollBar.new(Frame.zero(), self.style:getScrollTrackItem(), self.style:getScrollForwardItem(), self.style:getScrollBackItem())
    self.scrollBars = L{ self.horizontalScrollBar, self.verticalScrollBar }

    for scrollBar in self.scrollBars:it() do
        self:getDisposeBag():add(scrollBar:onScrollBackClick():addAction(function(s)
            self:scrollBack(s)
        end), scrollBar:onScrollBackClick())

        self:getDisposeBag():add(scrollBar:onScrollForwardClick():addAction(function(s)
            self:scrollForward(s)
        end), scrollBar:onScrollForwardClick())

        self:addSubview(scrollBar)

        scrollBar:setVisible(false)
        scrollBar:layoutIfNeeded()
    end

    self:getDisposeBag():addAny(self.scrollBars)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ScrollView:scrollForward(scrollBar)
    local newContentOffset = Frame.new(self:getContentOffset().x, self:getContentOffset().y, 0, 0)
    if scrollBar == self.horizontalScrollBar then
        newContentOffset.x = math.max(self:getContentOffset().x - self:getScrollDelta(), -self:getContentSize().width / 2)
    else
        local minY = -(self:getContentSize().height + self:getPadding().bottom - self:getSize().height)
        newContentOffset.y = math.max(self:getContentOffset().y - self:getScrollDelta(), minY)
    end
    self:setContentOffset(newContentOffset.x, newContentOffset.y)
end

function ScrollView:scrollBack(scrollBar)
    local newContentOffset = Frame.new(self:getContentOffset().x, self:getContentOffset().y, 0, 0)
    if scrollBar == self.horizontalScrollBar then
        newContentOffset.x = math.min(self:getContentOffset().x + self:getScrollDelta(), 0)
    else
        newContentOffset.y = math.min(self:getContentOffset().y + self:getScrollDelta(), 8)
    end
    self:setContentOffset(newContentOffset.x, newContentOffset.y)
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
-- Get the content size of the ScrollView.
--
-- @treturn Frame The content size of the ScrollView.
--
function ScrollView:getContentSize()
    return self.contentSize
end

---
-- Set a new content size for the ScrollView.
--
-- @tparam number contentWidth The new content width.
-- @tparam number contentHeight The new content height.
--
function ScrollView:setContentSize(contentWidth, contentHeight)
    self.contentSize.width = contentWidth
    self.contentSize.height = contentHeight

    self:updateContentView()
end

---
-- Get the padding of the ScrollView.
--
-- @treturn Padding The padding of the ScrollView.
--
function ScrollView:getPadding()
    return self.padding
end

---
-- Set a new padding for the ScrollView.
--
-- @tparam Padding padding The padding of the ScrollView.
--
function ScrollView:setPadding(padding)
    self.padding = padding
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

    if self.scrollEnabled then
        self:createScrollBars()
    end
end

---
-- Get the scroll delta value.
--
-- @treturn number The scroll delta value.
--
function ScrollView:getScrollDelta()
    return self.scrollDelta
end

---
-- Set a new scroll delta value.
--
-- @tparam number delta The new scroll delta value.
--
function ScrollView:setScrollDelta(delta)
    self.scrollDelta = delta
end

function ScrollView:canScroll()
    if os.clock() - self.lastScrollTime < self.scrollCooldown then
        return false
    end
    return true
end

function ScrollView:scrollUp()
    if not self:canScroll() then
        return false
    end
    self.lastScrollTime = os.clock()
    self.verticalScrollBar:onScrollBackClick():trigger(self.verticalScrollBar)
    return true
end

function ScrollView:scrollDown()
    if not self:canScroll() then
        return false
    end
    self.lastScrollTime = os.clock()
    self.verticalScrollBar:onScrollForwardClick():trigger(self.verticalScrollBar)
    return true
end

---
-- Ensure that the ScrollView is laid out based on its current state.
--
function ScrollView:layoutIfNeeded()
    if not View.layoutIfNeeded(self) or self.contentView == nil then
        return false
    end

    self.contentView.frame = Frame.new(self.contentOffset.x, self.contentOffset.y, self.frame.width, self.frame.height)
    self.contentView:setVisible(self:isVisible())

    self.contentView:setNeedsLayout()
    self.contentView:layoutIfNeeded()

    if self.horizontalScrollBar then
        self.horizontalScrollBar:setVisible(self:isScrollEnabled() and self.contentSize.width > self.frame.width)
        self.horizontalScrollBar:setPosition(0, self.frame.height - self.scrollBarSize)
        self.horizontalScrollBar:setSize(self.frame.width, self.scrollBarSize)
        self.horizontalScrollBar:layoutIfNeeded()
    end

    if self.verticalScrollBar then
        self.verticalScrollBar:setVisible(self:isScrollEnabled() and self.contentSize.height > self.frame.height)
        self.verticalScrollBar:setPosition(self.frame.width - self.scrollBarSize, 4)
        self.verticalScrollBar:setSize(self.scrollBarSize, self.frame.height - 8)
    end

    for scrollBar in self.scrollBars:it() do
        scrollBar:layoutIfNeeded()
    end

    self:updateContentView()

    return true
end

---
-- Updates the content view by managing visibility based on clipping and scrollability.
-- If scrolling is disabled, this function does nothing.
--
function ScrollView:updateContentView()
    if not self:isVisible() then
        return
    end
    local subviews = Q{ self:getContentView() }
    while not subviews:empty() do
        local view = subviews:pop()
        for _, subview in pairs(view.subviews) do
            subviews:push(subview)
        end
        if self:isScrollEnabled() then
            if self:shouldClipToBounds(view) then
                view:setVisible(false)
                view:layoutIfNeeded()
            else
                view:setVisible(true)
                view:layoutIfNeeded()
            end
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

function ScrollView:onMouseEvent(type, x, y, delta)
    if not self:isVisible() or not self:isScrollEnabled() or self:getContentSize().height <= self:getSize().height then
        return false
    end
    if type == Mouse.Event.Wheel then
        if delta < 0 then
            self.verticalScrollBar:onScrollForwardClick():trigger(self.verticalScrollBar)
        else
            self.verticalScrollBar:onScrollBackClick():trigger(self.verticalScrollBar)
        end
        return true
    end
    return false
end

return ScrollView