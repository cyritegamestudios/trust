---
-- A generic view class for creating and managing graphical views.
--
-- @class module
-- @name View
--

local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local FocusManager = require('cylibs/ui/focus/focus_manager')
local Frame = require('cylibs/ui/views/frame')
local Image = require('images')

local View = {}
View.__index = View
View.__type = "View"

num_created = 0
---
-- Creates a new View instance.
--
-- @treturn View The newly created View instance.
--
function View.new(frame)
    local self = setmetatable({}, View)

    self.visible = true
    self.userInteractionEnabled = false
    self.backgroundColor = Color.new(0, 0, 0, 0)
    self.backgroundView = Image.new()
    self.backgroundView:draggable(false)
    self.backgroundImageView = nil
    self.clipsToBounds = false
    self.frame = frame or Frame.new(0, 0, 0 , 0)
    self.needsLayout = true
    self.subviews = {}
    self.superview = nil
    self.editing = false
    self.focusable = true
    self.focusLocked = false
    self.uuid = os.time()..'-'..math.random(100000)
    self.destroyed = false
    self.disposeBag = DisposeBag.new()
    self.disposeBag:addAny(L{ self.backgroundView, self.backgroundImageView })

    self:setNeedsLayout()
    self:layoutIfNeeded()
    num_created = num_created + 1
    return self
end

---
-- Destroys the view, cleaning up its resources.
--
function View:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true

    self:removeFromSuperview()
    self:removeAllSubviews(true)

    self.disposeBag:destroy()

    num_created = num_created - 1
end

---
-- Gets the position of the view.
--
-- @treturn table A table with 'x' and 'y' representing the coordinates.
--
function View:getPosition()
    return { x = self.frame.x, y = self.frame.y }
end

---
-- Gets the position of the view in absolute coordinates.
--
-- @treturn table A table with 'x' and 'y' representing the coordinates.
--
function View:getAbsolutePosition()
    local x, y = self.frame.x, self.frame.y

    if self.superview then
        local parentPosition = self.superview:getAbsolutePosition()

        x = parentPosition.x + self.frame.x
        y = parentPosition.y + self.frame.y
    end

    return { x = x, y = y }
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate to set.
-- @tparam number y The y-coordinate to set.
--
function View:setPosition(x, y)
    if self.frame.x == x and self.frame.y == y then
        return
    end
    self.frame = Frame.new(x, y, self.frame.width, self.frame.height)

    for _, subview in pairs(self.subviews) do
        subview:setPosition(x - self.frame.x, y - self.frame.y)
    end

    self:setNeedsLayout()
end

---
-- Gets the size of the view.
--
-- @treturn table A table with 'width' and 'height' representing the dimensions.
--
function View:getSize()
    return { width = self.frame.width, height = self.frame.height }
end

---
-- Sets the size of the view.
--
-- @tparam number width The width to set.
-- @tparam number height The height to set.
--
function View:setSize(width, height)
    if self.frame.width == width and self.frame.height == height then
        return
    end
    self.frame = Frame.new(self.frame.x, self.frame.y, width, height)

    self:setNeedsLayout()
end

---
-- Checks if the view is currently visible.
--
-- @treturn boolean True if the view is visible, false otherwise.
--
function View:isVisible()
    if self.superview and not self.superview:isVisible() then
        return false
    end
    return self.visible
end

function View:getAbsoluteVisibility()
    if self.superview then
        return self:isVisible() and self.superview:isVisible()
    end
    return self:isVisible()
end

---
-- Sets the visibility of the view.
--
-- @tparam boolean visible True to make the view visible, false to hide it.
--
function View:setVisible(visible)
    if self.visible == visible then
        return
    end
    self.visible = visible
    for _, subview in pairs(self.subviews) do
        -- FIXME: should probably just call setVisible instead
        --subview:setVisible(visible)
        subview:setNeedsLayout()
        subview:layoutIfNeeded()
    end
    self:setNeedsLayout()
end

---
-- Checks if user interaction is enabled for the view.
--
-- @treturn boolean True if user interaction is enabled, false otherwise.
--
function View:isUserInteractionEnabled()
    return self.userInteractionEnabled
end

---
-- Sets whether user interaction is enabled for the view.
--
-- @tparam boolean userInteractionEnabled True to enable user interaction, false otherwise.
--
function View:setUserInteractionEnabled(userInteractionEnabled)
    self.userInteractionEnabled = userInteractionEnabled
end

---
-- Gets the current clipsToBounds value of the view.
-- @treturn boolean The current clipsToBounds value.
--
function View:getClipsToBounds()
    return self.clipsToBounds
end

---
-- Sets whether the view clips its content to its bounds.
-- @tparam boolean clipsToBounds True to clip the content, false otherwise.
--
function View:setClipsToBounds(clipsToBounds)
    self.clipsToBounds = clipsToBounds
end

---
-- Sets the background color of the view.
--
-- @tparam Color color The color to set as the background.
--
function View:setBackgroundColor(color)
    self.backgroundColor = color
    self:setNeedsLayout()
end

---
-- Sets the background image of the view.
--
-- @tparam string imagePath The color to set as the background.
--
function View:setBackgroundImageView(backgroundImageView)
    if backgroundImageView == nil then
        if self.backgroundImageView then
            self.backgroundImageView:removeFromSuperview()
            self.backgroundImageView:setVisible(false)
            self.backgroundImageView:layoutIfNeeded()
            self.backgroundImageView = nil
        end
    else
        if self.backgroundImageView ~= nil then
            return
        end
        self.backgroundImageView = backgroundImageView

        self:addSubview(self.backgroundImageView)

        self:setNeedsLayout()
        self:layoutIfNeeded()
    end
end

---
-- Returns the background image view
--
-- @treturn View Background image view
--
function View:getBackgroundImageView()
    return self.backgroundImageView
end

---
-- Gets the navigation bar associated with the view.
--
-- @treturn NavigationBar The navigation bar associated with the view.
--
function View:getNavigationBar()
    return self.navigationBar
end

---
-- Sets the navigation bar for the view.
--
-- @tparam NavigationBar navigationBar The navigation bar to set.
function View:setNavigationBar(navigationBar)
    self.navigationBar = navigationBar

    self:addSubview(self.navigationBar)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Sets the title of the navigation bar, if it exists.
--
-- @tparam string title The navigation bar title.
function View:setTitle(title)
    if self.navigationBar then
        self.navigationBar:setTitle(title)
    end
end

---
-- Resigns focus from the view.
--
function View:resignFocus()
    FocusManager.shared():resignFocus(self)
end

---
-- Request focus for the view.
--
-- @treturn boolean True if the view is focused.
function View:requestFocus()
    return FocusManager.shared():requestFocus(self)
end

---
-- Returns whether the view should request focus when being presented.
--
-- @treturn boolean If the view should request focus.
function View:shouldRequestFocus()
    return self.focusable
end

---
-- Sets whether the view should request focus when being presented.
--
-- @tparam boolean focusable Whether the view should request focus.
--
function View:setShouldRequestFocus(focusable)
    self.focusable = focusable
end

---
-- Returns whether the view should resign focus if it currently has focus.
--
-- @treturn boolean If the view should resign focus.
function View:shouldResignFocus()
    return self:hasFocus() and not self.focusLocked
end

---
-- Sets whether the view should resign focus if it currently has focus.
--
-- @tparam boolean resignFocus Whether the view should resign focus.
--
function View:setShouldResignFocus(resignFocus)
    self.focusLocked = not resignFocus
end

---
-- Returns whether the view has focus.
--
-- @treturn boolean If the view has focus.
function View:hasFocus()
    return self.focused
end

---
-- Sets whether the view has focus.
--
-- @tparam boolean hasFocus Whether the view has focus.
--
function View:setHasFocus(hasFocus)
    self.focused = hasFocus
end

---
-- Called when this View has focus and a keyboard event fires.
--
function View:onKeyboardEvent(key, pressed, flags, blocked)
    if pressed then
        if L{ 1, 205 }:contains(key) then
            self:resignFocus()
        end
    end
end

---
-- Sets whether the view is in edit mode.
--
-- @tparam boolean editing The new value for `editing`.
--
function View:setEditing(editing)
    if self.editing == editing then
        return false
    end
    self.editing = editing

    if self.backgroundImageView then
        self.backgroundImageView:setEditing(editing)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return true
end

---
-- Returns whether the view is in edit mode.
--
-- @treturn boolean True if the view is in edit mode, false otherwise.
--
function View:isEditing()
    return self.editing
end

---
-- Adds a subview to the current view.
--
-- @tparam View view The view to be added as a subview.
--
function View:addSubview(view)
    if self.subviews[view:getUUID()] ~= nil then
        return
    end
    self.subviews[view:getUUID()] = view
    view.superview = self
    view:setNeedsLayout()
end

---
-- Removes a subview from the current view.
--
-- @tparam View view The view to be removed from the subviews.
--
function View:removeSubview(view)
    self.subviews[view:getUUID()] = nil
    view.superview = nil
end

---
-- Removes all subviews from the current view.
--
-- @tparam boolean destroy Optionally call destroy() on subviews.
--
function View:removeAllSubviews(destroy)
    destroy = destroy or false
    for _, subview in pairs(self.subviews) do
        subview.superview = nil
        if destroy then
            subview:destroy()
        end
    end
    self.subviews = {}
end

---
-- Removes the view from its superview.
--
function View:removeFromSuperview()
    if self.superview then
        self.superview:removeSubview(self)
    end
end

---
-- Flags the view for a layout update.
--
function View:setNeedsLayout()
    self.needsLayout = true
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function View:layoutIfNeeded()
    if not self.needsLayout or self.destroyed then
        return false
    end
    self.needsLayout = false

    local position = self:getAbsolutePosition()

    local x = position.x
    local y = position.y

    self.backgroundView:alpha(self.backgroundColor.alpha)
    self.backgroundView:color(self.backgroundColor.red, self.backgroundColor.green, self.backgroundColor.blue)
    self.backgroundView:pos(x, y)
    self.backgroundView:size(self.frame.width, self.frame.height)
    self.backgroundView:visible(self:isVisible())

    if self.backgroundImageView then
        self.backgroundImageView:setSize(self.frame.width, self.frame.height)
        self.backgroundImageView:setVisible(self:isVisible())
        self.backgroundImageView:layoutIfNeeded()
    end

    if self.navigationBar then
        self.navigationBar:setPosition(0, -self.navigationBar:getSize().height - 5)
        self.navigationBar:setSize(self.frame.width, self.navigationBar:getSize().height)
        self.navigationBar:setVisible(self:isVisible())
        self.navigationBar:layoutIfNeeded()
    end

    for _, subview in pairs(self.subviews) do
        if subview ~= self.backgroundImageView then
            subview:setNeedsLayout()
            subview:layoutIfNeeded()
        end
    end
    return true
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function View:hitTest(x, y)
    -- FIXME: add manual checking using absolute coordinates
    return self.backgroundView:hover(x, y)
end

---
-- Returns the DisposeBag associated with this view.
--
-- @treturn DisposeBag The associated DisposeBag.
--
function View:getDisposeBag()
    return self.disposeBag
end

---
-- Gets the unique identifier of the view.
--
-- @treturn string The unique identifier of the view.
--
function View:getUUID()
    return self.uuid
end

---
-- Compares two View instances for equality based on their UUIDs.
-- @tparam View otherItem The other View to compare.
-- @treturn bool True if the Views have the same UUID, false otherwise.
--
function View:__eq(otherItem)
    return getmetatable(otherItem).__type == View.__type
            and self:getUUID() == otherItem:getUUID()
end

return View
