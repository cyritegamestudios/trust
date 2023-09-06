local View = require('cylibs/ui/view')

local ListItemView = setmetatable({}, {__index = View })
ListItemView.__index = ListItemView

function ListItemView.new(item)
    local self = setmetatable(View.new(), ListItemView)

    self.item = item

    self:set_size(40, 40)

    return self
end

function ListItemView:destroy()
    View.destroy(self)
end

function ListItemView:getItem()
    return self.item
end

function ListItemView:setItem(item)
    self.item = item
end

function ListItemView:getStyle()
    return self.item:getStyle()
end

function ListItemView:render()
end

return ListItemView