local TextItem = require('cylibs/ui/collection_view/items/text_item')

local NavigationItem = setmetatable({}, { __index = TextItem })
NavigationItem.__index = NavigationItem


NavigationItem.__type = "NavigationItem"

function NavigationItem.new(text, style)
    local self = setmetatable(TextItem.new(text, style), NavigationItem)

    return self
end

return NavigationItem