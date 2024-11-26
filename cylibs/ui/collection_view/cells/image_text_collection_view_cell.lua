local ToggleButtonItem = require('cylibs/ui/collection_view/items/toggle_button_item')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')

local ImageTextCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ImageTextCollectionViewCell.__index = ImageTextCollectionViewCell
ImageTextCollectionViewCell.__type = "ImageTextCollectionViewCell"


function ImageTextCollectionViewCell.new(imageTextItem)
    local self = setmetatable(CollectionViewCell.new(imageTextItem), ImageTextCollectionViewCell)

    self.imageView = ImageCollectionViewCell.new(imageTextItem:getImageItem())
    self:addSubview(self.imageView)

    self.textView = TextCollectionViewCell.new(imageTextItem:getTextItem())
    self:addSubview(self.textView)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ImageTextCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    local xPos = self:getItem():getImageItem():getSize().width + self:getItem():getSpacing()
    self.textView:setPosition(xPos, 0)
    self.textView:setSize(self:getSize().width - xPos, self:getSize().height)
    self.textView:setVisible(self:isVisible())
    self.textView:setNeedsLayout()
    self.textView:layoutIfNeeded()

    return true
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function ImageTextCollectionViewCell:setSelected(selected)
    if selected == self.selected then
        return false
    end

    self.textView:setSelected(selected)

    CollectionViewCell.setSelected(self, selected)

    return true
end

function ImageTextCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.imageView:setItem(item:getImageItem())
    self.textView:setItem(item:getTextItem())
end

return ImageTextCollectionViewCell