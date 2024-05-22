local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')

local SectionHeaderCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
SectionHeaderCollectionViewCell.__index = SectionHeaderCollectionViewCell
SectionHeaderCollectionViewCell.__type = "SectionHeaderCollectionViewCell"

function SectionHeaderCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), SectionHeaderCollectionViewCell)

    self.imageView = ImageCollectionViewCell.new(item:getImageItem())
    self.titleView = TextCollectionViewCell.new(item:getTitleItem())

    self:addSubview(self.imageView)
    self:addSubview(self.titleView)

    self:setItem(item)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SectionHeaderCollectionViewCell:destroy()
    CollectionViewCell.destroy(self)
end

function SectionHeaderCollectionViewCell:setItem(item)
    self.imageView:setItem(item:getImageItem())
    self.imageView:setSize(item:getImageItem():getSize().width, item:getImageItem():getSize().height)
    self.imageView:setPosition(0, (self:getSize().height - item:getImageItem():getSize().height) / 2)

    self.titleView:setItem(item:getTitleItem())
    self.titleView:setSize(self:getSize().width - self.imageView:getSize().width, self:getSize().height)
    self.titleView:setPosition(self.imageView:getSize().width + 4, 0)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    CollectionViewCell.setItem(self, self:getItem())
end

return SectionHeaderCollectionViewCell