local TabItem = {}
TabItem.__index = TabItem

---
-- Creates a new TabItem instance.
--
-- @tparam string tabName The name or label of the tab.
-- @tparam View view The view associated with the tab.
-- @treturn TabItem The newly created TabItem instance.
--
function TabItem.new(tabName, view)
    local self = setmetatable({}, TabItem)
    self.tabName = tabName
    self.view = view
    return self
end

---
-- Gets the name or label of the tab.
--
-- @treturn string The name or label of the tab.
--
function TabItem:getTabName()
    return self.tabName
end

---
-- Gets the view associated with the tab.
--
-- @treturn View The view associated with the tab.
--
function TabItem:getView()
    return self.view
end

return TabItem