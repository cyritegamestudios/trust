local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local ImageListItemView = require('cylibs/ui/items/images/image_list_item_view')

local ImageListItem = setmetatable({}, { __index = ListItem })
ImageListItem.__index = ImageListItem

---
-- Creates a new ImageListItem instance with an associated image path and dimensions.
--
-- @tparam string imagePath The path to the associated image.
-- @tparam number imageWidth The width of the associated image.
-- @tparam number imageHeight The height of the associated image.
-- @tparam T extras Extra metadata associated with the image.
-- @treturn ImageListItem The newly created ImageListItem instance.
--
function ImageListItem.new(imagePath, imageWidth, imageHeight, extras)
    local self = setmetatable(ListItem.new({width = imageWidth, height = imageHeight, extras = extras or {} }, ListViewItemStyle.DarkMode.Image, imagePath, ImageListItemView.new), ImageListItem)
    self.imagePath = imagePath
    self.imageWidth = imageWidth
    self.imageHeight = imageHeight
    return self
end

---
-- Get the path to the associated image.
--
-- @treturn string The image path.
--
function ImageListItem:getImagePath()
    return self.imagePath
end

---
-- Get the dimensions of the associated image.
--
-- @treturn number imageWidth The width of the associated image.
-- @treturn number imageHeight The height of the associated image.
--
function ImageListItem:getImageSize()
    return self.imageWidth, self.imageHeight
end

---
-- Check if two ImageListItem instances are equal based on their identifiers.
--
-- @tparam ImageListItem otherItem The other ImageListItem to compare with.
-- @treturn bool True if the items are equal, false otherwise.
--
function ImageListItem:__eq(otherItem)
    return self:isEqual(otherItem)
end

return ImageListItem
