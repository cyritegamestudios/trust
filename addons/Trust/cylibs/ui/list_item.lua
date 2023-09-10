local ListItemView = require('cylibs/ui/list_item_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')

local ListItem = {}
ListItem.__index = ListItem

local defaultItemStyle = ListViewItemStyle.new(
        {alpha = 255, red = 0, green = 0, blue = 0},
        {alpha = 255, red = 0, green = 0, blue = 0},
        "Arial",
        14,
        {red = 255, green = 255, blue = 255},
        2,
        0,
        0,
        false
)

---
-- Creates a new ListItem instance.
--
-- @tparam any data The data associated with the ListItem.
-- @tparam ListViewItemStyle style (optional) The style to apply to the ListItem. Defaults to the default style if not specified.
-- @tparam any identifier An identifier for the ListItem.
-- @tparam function viewConstructor (optional) A constructor function for the ListItem's view. Defaults to ListItemView.new if not specified.
-- @treturn ListItem The newly created ListItem instance.
--
function ListItem.new(data, style, identifier, viewConstructor)
    local self = setmetatable({}, ListItem)
    self.data = data
    self.style = style or defaultItemStyle
    self.identifier = identifier
    self.viewConstructor = viewConstructor or ListItemView.new
    return self
end

function ListItem:destroy()
    self.viewConstructor = nil
end

function ListItem:getData()
    return self.data
end

function ListItem:getStyle()
    return self.style
end

function ListItem:getIdentifier()
    return self.identifier
end

function ListItem:getViewConstructor()
    return self.viewConstructor
end

function ListItem:isEqual(otherItem)
    return self:getIdentifier() == otherItem:getIdentifier()
end

function ListItem:__eq(otherItem)
    return self:isEqual(otherItem)
end

return ListItem