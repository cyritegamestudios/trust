local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')

local ButtonCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ButtonCollectionViewCell.__index = ButtonCollectionViewCell


function ButtonCollectionViewCell.new(buttonItem)
    local self = setmetatable(CollectionViewCell.new(buttonItem), ButtonCollectionViewCell)

    self.disposeBag = DisposeBag.new()

    self:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(item:getSize().width)
        return cell
    end)

    self.textView = TextCollectionViewCell.new(buttonItem:getTextItem())
    self.textView:setEstimatedSize(buttonItem:getSize().height + 2)
    self.textView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    self:addSubview(self.textView)

    self.buttonView = CollectionView.new(dataSource, HorizontalFlowLayout.new())
    self.buttonView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    local items = L{
        IndexedItem.new(buttonItem:getImageItems().left, IndexPath.new(1, 1)),
        IndexedItem.new(buttonItem:getImageItems().center, IndexPath.new(1, 2)),
        IndexedItem.new(buttonItem:getImageItems().right, IndexPath.new(1, 3)),
    }
    self.buttonView:getDataSource():addItems(items)

    self:setBackgroundImageView(self.buttonView)

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(item:getSize().width)
        return cell
    end)

    self.highlightedButtonView = CollectionView.new(dataSource, HorizontalFlowLayout.new())
    self.highlightedButtonView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    local items = L{
        IndexedItem.new(buttonItem:getSelectedImageItems().left, IndexPath.new(1, 1)),
        IndexedItem.new(buttonItem:getSelectedImageItems().center, IndexPath.new(1, 2)),
        IndexedItem.new(buttonItem:getSelectedImageItems().right, IndexPath.new(1, 3)),
    }
    self.highlightedButtonView:getDataSource():addItems(items)

    self.highlightedButtonView:setVisible(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self.disposeBag:addAny(L{ self.textView, self.buttonView, self.highlightedButtonView })

    return self
end

function ButtonCollectionViewCell:destroy()
    CollectionViewCell.destroy(self)

    self.disposeBag:destroy()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ButtonCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    local textColor = self:getItem():getTextItem():getStyle():getFontColor()
    if self:getItem():getEnabled() then
        self.textView:setTextColor(textColor)
    else
        self.textView:setTextColor(Color.new(textColor.alpha * 0.5, textColor.red, textColor.green, textColor.blue))
    end
    self.textView:setPosition(10, self.textView:getPosition().y)
    self.textView:setSize(self:getSize().width, self:getSize().height)
    self.textView:layoutIfNeeded()

    return true
end

---
-- Sets the selection state of the CollectionViewCell.
-- @tparam boolean selected The new selection state.
--
function ButtonCollectionViewCell:setHighlighted(highlighted)
    if highlighted == self.highlighted then
        return
    end

    self.textView:setHighlighted(highlighted)

    self:setBackgroundImageView(nil)

    if highlighted then
        self:setBackgroundImageView(self.highlightedButtonView)
    else
        self:setBackgroundImageView(self.buttonView)
    end

    CollectionViewCell.setHighlighted(self, highlighted)
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function ButtonCollectionViewCell:hitTest(x, y)
    return self.buttonView:hitTest(x, y)
end

return ButtonCollectionViewCell