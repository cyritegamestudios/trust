local ImageView = require('cylibs/ui/image_view')

local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')

local ImageCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ImageCollectionViewCell.__index = ImageCollectionViewCell
ImageCollectionViewCell.__type = "ImageCollectionViewCell"


function ImageCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), ImageCollectionViewCell)

    self.imageView = ImageView.new(item:getRepeat().x, item:getRepeat().y, item:getAlpha())

    self:addSubview(self.imageView)

    self:setSize(item:getSize().width, item:getSize().height)
    self:setVisible(false)

    self:getDisposeBag():addAny(L{ self.imageView })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ImageCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.imageView.repeatX = item:getRepeat().x
    self.imageView.repeatY = item:getRepeat().y
    self.imageView.alpha = item:getAlpha()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ImageCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    if self.imageView:getSize().width ~= self:getSize().width or self.imageView:getSize().height ~= self:getSize().height then
        self.imageView:setSize(self:getSize().width, self:getSize().height)

        self.imageView:layoutIfNeeded()
    end

    local isVisible = self:getAbsoluteVisibility() and self:isVisible()
    if isVisible then
        self.imageView:loadImage(self:getItem():getImagePath())
    end
    self.imageView:setVisible(isVisible)

    return true
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function ImageCollectionViewCell:hitTest(x, y)
    return self.imageView:hitTest(x, y)
end

return ImageCollectionViewCell