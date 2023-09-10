local ImageView = require('cylibs/ui/image_view')
local ListItemView = require('cylibs/ui/list_item_view')

local ImageListItemView = setmetatable({}, {__index = ListItemView })
ImageListItemView.__index = ImageListItemView

---
-- Creates a new ImageListItemView instance.
--
-- @tparam ImageListItem item The item to display in the view.
-- @treturn ImageListItemView The newly created ImageListItemView instance.
--
function ImageListItemView.new(item)
    local self = setmetatable(ListItemView.new(item), ImageListItemView)

    self.imageView = ImageView.new(item:getImagePath())

    self:addChild(self.imageView)

    local width, height = item:getImageSize()

    self:set_size(width, height)

    local backgroundColor = item.style:getDefaultBackgroundColor()
    self:set_color(backgroundColor.alpha, backgroundColor.red, backgroundColor.green, backgroundColor.blue)
    self:render()
    return self
end

function ImageListItemView:destroy()
    ListItemView.destroy(self)

    self.imageView:destroy()
end

function ImageListItemView:hover(x, y)
    return self.imageView:hover(x, y)
end

function ImageListItemView:layoutIfNeeded()
    ListItemView.layoutIfNeeded(self)

    local x, y = self:get_pos()
    local width, height = self:get_size()

    self.imageView:set_pos(x, y)
    self.imageView:setImageSize(width, height)
    self.imageView:set_visible(self:is_visible())
    self.imageView:render()
end

return ImageListItemView