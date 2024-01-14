local MenuItem = {}
MenuItem.__index = MenuItem
MenuItem.__type = "MenuItem"

---
-- Creates a new MenuItem.
--
-- @param buttonItems A list of ButtonItems associated with this MenuItem.
-- @param childMenuItems A table mapping text strings to child MenuItems.
-- @param contentViewConstructor A function that returns a ContentView for this MenuItem.
-- @treturn MenuItem The newly created MenuItem.
--
function MenuItem.new(buttonItems, childMenuItems, contentViewConstructor)
    local self = setmetatable({}, MenuItem)

    self.buttonItems = buttonItems
    self.childMenuItems = childMenuItems
    self.contentViewConstructor = contentViewConstructor

    return self
end

---
-- Retrieves the list of ButtonItems associated with this MenuItem.
--
-- @treturn list A list of ButtonItems.
--
function MenuItem:getButtonItems()
    return self.buttonItems
end

---
-- Gets the child MenuItem with the specified text.
--
-- @tparam string text The text of the child MenuItem to retrieve.
-- @treturn MenuItem|nil The child MenuItem with the specified text, or nil if not found.
--
function MenuItem:getChildMenuItem(text)
    return self.childMenuItems[text]
end

---
-- Sets the child MenuItem with the specified text.
--
-- @tparam string text The name of the child MenuItem.
-- @tparam MenuItem|nil The child MenuItem with the specified text, or nil if removing.
--
function MenuItem:setChildMenuItem(text, childMenuItem)
    self.childMenuItems[text] = childMenuItem
end

---
-- Gets the ContentView associated with this MenuItem.
--
-- @tparam table args (optional) Args to pass to the contentViewConstructor
-- @treturn ContentView The ContentView associated with this MenuItem.
--
function MenuItem:getContentView(args)
    if self.contentViewConstructor ~= nil then
        return self.contentViewConstructor(args)
    end
    return nil
end

---
-- Checks if this MenuItem is equal to another TextItem.
--
-- @tparam any otherItem The other item to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function MenuItem:__eq(otherItem)
    return otherItem.__type == MenuItem.__type
end

return MenuItem