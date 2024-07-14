local MenuItem = {}
MenuItem.__index = MenuItem
MenuItem.__type = "MenuItem"

---
-- Creates a new MenuItem.
--
-- @param list buttonItems A list of ButtonItems associated with this MenuItem.
-- @param list childMenuItems A table mapping text strings to child MenuItems.
-- @param function contentViewConstructor A function that returns a ContentView for this MenuItem.
-- @param string titleText Title text for this MenuItem.
-- @param string descriptionText Description text for this MenuItem.
-- @param boolean keepViews Whether this MenuItem should keep views of the parent MenuItem.
--
-- @treturn MenuItem The newly created MenuItem.
--
function MenuItem.new(buttonItems, childMenuItems, contentViewConstructor, titleText, descriptionText, keepViews)
    local self = setmetatable({}, MenuItem)

    self.uuid = os.time()..'-'..math.random(100000)
    self.buttonItems = buttonItems
    self.childMenuItems = childMenuItems
    self.contentViewConstructor = contentViewConstructor
    self.descriptionText = descriptionText
    self.titleText = titleText
    self.keepViews = keepViews

    return self
end

---
-- Creates a new MenuItem that executes an action when selected.
--
-- @param function callback The menu item action.
-- @param string titleText Title text for this MenuItem.
-- @param string descriptionText Description text for this MenuItem.
-- @param boolean keepViews Whether this MenuItem should keep views of the parent MenuItem.
--
-- @treturn MenuItem The newly created MenuItem.
--
function MenuItem.action(callback, titleText, descriptionText)
    local self = MenuItem.new(L{}, L{}, nil, titleText, descriptionText, false)

    self.callback = callback

    return self
end

function MenuItem:destroy()
    self.callback = nil
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
function MenuItem:getContentView(args, infoView)
    if self.contentViewConstructor ~= nil then
        return self.contentViewConstructor(args, infoView)
    end
    return nil
end

---
-- Gets the title text for this menu item.
--
-- @treturn string The title text for this MenuItem.
--
function MenuItem:getTitleText()
    return self.titleText
end

---
-- Gets the description text for this menu item.
--
-- @treturn string The description text for this MenuItem.
--
function MenuItem:getDescriptionText()
    return self.descriptionText
end

---
-- Gets the action callback for this menu item.
--
-- @treturn function The action callback for this MenuItem.
--
function MenuItem:getAction()
    return self.callback
end

---
-- Checks if this MenuItem is equal to another TextItem.
--
-- @tparam any otherItem The other item to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function MenuItem:__eq(otherItem)
    return otherItem.__type == MenuItem.__type and otherItem:getTitleText() == self:getTitleText()
            and otherItem:getDescriptionText() == self:getDescriptionText()
end

---
-- Returns the unique identifier for this MenuItem.
--
-- @treturn number Unique identifier
--
function MenuItem:getUUID()
    return self.uuid
end

return MenuItem