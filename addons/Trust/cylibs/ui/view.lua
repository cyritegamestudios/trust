local Image = require('images')

---
-- A generic view class for creating and managing graphical views.
--
-- @classmod View
--

local View = {}
View.__index = View

---
-- Creates a new View instance.
--
-- @treturn View The newly created View instance.
--
function View.new()
    local self = setmetatable({}, View)

    self.uuid = os.time()..'-'..math.random(1000)
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.visible = true
    self.selected = false
    self.selectable = false
    self.highlightable = false
    self.destroyed = false
    self.backgroundImageView = Image.new()
    self.backgroundImageView:draggable(false)
    self.backgroundImageView:visible(false)
    self.children = L{}

    --windower.prim.create(self.uuid)

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

    self:removeAllChildren()

    self.backgroundImageView:destroy()
    self.backgroundImageView = nil
end

---
-- Checks whether the view has been destroyed.
--
-- @treturn boolean Returns `true` if the view has been destroyed, otherwise `false`.
--
function View:is_destroyed()
    return self.destroyed
end

---
-- Renders the view's content.
--
function View:render()
    -- Implement the rendering logic for the view's content.
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate of the new position.
-- @tparam number y The y-coordinate of the new position.
--
function View:set_pos(x, y)
    self.x = x
    self.y = y
    self.backgroundImageView:pos(x, y)
    --windower.prim.set_position(self:get_uuid(), x, y)
end

---
-- Gets the current position of the view.
--
-- @treturn number x The x-coordinate of the view's position.
-- @treturn number y The y-coordinate of the view's position.
--
function View:get_pos()
    return self.x, self.y
end

---
-- Checks if the view is currently visible.
--
-- @treturn boolean Returns `true` if the view is visible, `false` otherwise.
--
function View:is_visible()
    return self.visible
end

---
-- Sets the visibility of the view.
--
-- @tparam boolean visible If `true`, the view will be set to visible; if `false`, it will be set to hidden.
--
function View:set_visible(visible)
    self.visible = visible
    self.backgroundImageView:visible(visible)
    for child in self.children:it() do
        child:set_visible(visible)
    end
end

---
-- Gets the current size of the view.
--
-- @treturn number width The width of the view.
-- @treturn number height The height of the view.
--
function View:get_size()
    return self.width, self.height
end

---
-- Sets the size of the view.
--
-- @tparam number width The new width of the view.
-- @tparam number height The new height of the view.
--
function View:set_size(width, height)
    self.width = width
    self.height = height
    self.backgroundImageView:size(width, height)
end

---
-- Sets the color of the view.
--
-- @tparam number alpha The alpha (transparency) component of the color, ranging from 0 (fully transparent) to 255 (fully opaque).
-- @tparam number red The red component of the color, ranging from 0 to 255.
-- @tparam number green The green component of the color, ranging from 0 to 255.
-- @tparam number blue The blue component of the color, ranging from 0 to 255.
--
function View:set_color(alpha, red, green, blue)
    self.backgroundImageView:color(red, green, blue)
    self.backgroundImageView:alpha(alpha)
    --windower.prim.set_color(self:get_uuid(), alpha, red, green, blue)
end

---
-- Sets the selected state of the view.
--
-- @tparam boolean selected Whether the view should be selected (true) or not (false).
--
function View:set_selected(selected)
    self.selected = selected
end

---
-- Checks whether the view is selectable.
--
-- @treturn boolean Returns `true` if the view is selectable, otherwise `false`.
--
function View:is_selectable()
    return self.selectable
end

---
-- Sets whether the view is selectable.
--
-- @tparam boolean selectable Whether the view should be selectable (true) or not (false).
--
function View:set_selectable(selectable)
    self.selectable = selectable
end


---
-- Checks whether the view is selected.
--
-- @treturn boolean Returns `true` if the view is selected, otherwise `false`.
--
function View:is_selected()
    return self.selected
end

-- Sets whether the view is highlighted or not.
--
-- @tparam boolean highlighted Set to true to highlight the view, false to unhighlight it.
--
function View:set_highlighted(highlighted)
    self.highlighted = highlighted
end

-- Checks if the view is currently highlighted.
--
-- @treturn boolean Returns true if the view is highlighted, false otherwise.
--
function View:is_highlighted()
    return self.highlighted
end

---
-- Sets whether the view is highlightable or not.
--
-- @tparam boolean highlightable Set to true to make the view highlightable, false to make it non-highlightable.
--
function View:set_highlightable(highlightable)
    self.highlightable = highlightable
end

---
-- Checks if the view is currently highlightable.
--
-- @treturn boolean Returns true if the view is highlightable, false otherwise.
--
function View:is_highlightable()
    return self.highlightable
end

---
-- Checks if the specified coordinates are within the hover area of the view.
--
-- @tparam number x The x-coordinate to check.
-- @tparam number y The y-coordinate to check.
-- @treturn boolean Returns `true` if the coordinates are within the hover area, otherwise `false`.
--
function View:hover(x, y)
    if not self:is_visible() then
        return false
    end

    if self.backgroundImageView:hover(x, y) then
        return true
    end

    local xPos, yPos = self:get_pos()
    local width, height = self:get_size()
    local buffer = 0

    return x >= xPos - buffer and x <= xPos + width + buffer and y >= yPos - buffer and y <= yPos + height + buffer
end

---
-- Adds a view as a child.
--
-- @tparam View view The view to add.
--
function View:addChild(view)
    if not self:containsChild(view) then
        self.children:append(view)
    end
end

---
-- Removes a child view.
--
-- @tparam View view The view to add.
--
function View:removeChild(view)
    local newChildren = L{}
    for child in self:getChildren():it() do
        if child ~= view then
            newChildren:append(child)
        end
    end
    self.children = newChildren
end

---
-- Gets a list of child views associated with this view.
--
-- @treturn table An array-like table containing child views of type `View`.
--
function View:getChildren()
    return self.children
end

---
-- Removes all child views.
--
function View:removeAllChildren()
    self.children = L{}
end

---
-- Checks if the tabbed interface already contains the specified view based on its UUID.
--
-- @tparam View view The view to check.
-- @treturn boolean Returns `true` if the view is already a child, otherwise `false`.
--
function View:containsChild(view)
    local viewUUID = view:get_uuid()
    for v in self.children:it() do
        if v:get_uuid() == viewUUID then
            return true
        end
    end
    return false
end


---
-- Gets the unique identifier of the view.
--
-- @treturn string The unique identifier of the view.
--
function View:get_uuid()
    return self.uuid
end

return View
