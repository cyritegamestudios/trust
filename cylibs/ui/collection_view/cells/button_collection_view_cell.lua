local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local DisposeBag = require('cylibs/events/dispose_bag')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')

local ButtonCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ButtonCollectionViewCell.__index = ButtonCollectionViewCell
ButtonCollectionViewCell.__type = "ButtonCollectionViewCell"


function ButtonCollectionViewCell.new(buttonItem)
    local self = setmetatable(CollectionViewCell.new(buttonItem), ButtonCollectionViewCell)

    self.buttonState = nil
    self.backgroundViews = {}
    self.disposeBag = DisposeBag.new()

    self:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    self.textView = TextCollectionViewCell.new(buttonItem:getTextItem())
    self.textView:setEstimatedSize(buttonItem:getSize().height + 2)
    self.textView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)
    self.textView:setVisible(false)

    self:addSubview(self.textView)

    self:setButtonState(ButtonItem.State.Default)

    self.disposeBag:addAny(L{ self.textView })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ButtonCollectionViewCell:createButton(buttonItem, buttonState)
    local items = buttonItem:getImageItem(buttonState):getAllImageItems(L{ ResizableImageItem.Left, ResizableImageItem.Center, ResizableImageItem.Right })
    if items:empty() then
        return nil
    end

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(item:getSize().width)
        cell:setClipsToBounds(false)
        return cell
    end)

    local buttonView = CollectionView.new(dataSource, HorizontalFlowLayout.new(), nil, CollectionViewStyle.empty())
    buttonView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    local rowIndex = 0
    local items = items:map(function(item)
        rowIndex = rowIndex + 1
        return IndexedItem.new(item, IndexPath.new(1, rowIndex))
    end)

    buttonView:getDataSource():addItems(items)

    buttonView:setScrollEnabled(false)
    buttonView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)
    buttonView:setVisible(false)
    buttonView:layoutIfNeeded()

    self.backgroundViews[buttonState] = buttonView

    self.disposeBag:addAny(L{ buttonView })

    return buttonView
end

function ButtonCollectionViewCell:destroy()
    CollectionViewCell.destroy(self)

    self.disposeBag:destroy()
end

---
-- Returns the background view for a given button state.
-- @tparam ButtonItem.State buttonState Button state
-- @treturn View Background view for the button state.
--
function ButtonCollectionViewCell:backgroundViewForState(buttonState)
    return self.backgroundViews[buttonState]
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ButtonCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    if self:getItem():getEnabled() then
        self.textView:setAlpha(255)
    else
        self.textView:setAlpha(150)
    end
    self.textView:setPosition(10, self.textView:getPosition().y)
    self.textView:setSize(self:getSize().width, self:getSize().height)
    self.textView:layoutIfNeeded()

    return true
end

---
-- Sets the button state of the cell.
-- @tparam ButtonItem.State buttonState The new button state.
--
function ButtonCollectionViewCell:setButtonState(buttonState)
    if self.buttonState == buttonState then
        return
    end
    self.buttonState = buttonState

    local buttonView = self:backgroundViewForState(buttonState) or self:createButton(self:getItem(), buttonState)
    if buttonView then
        self:setBackgroundImageView(nil)
        self:setBackgroundImageView(buttonView)
    end
end

---
-- Sets the highlighted state of the cell.
-- @tparam boolean selected The new highlighted state.
--
function ButtonCollectionViewCell:setHighlighted(highlighted)
    if highlighted == self.highlighted or self:isSelected() then
        return
    end

    self.textView:setHighlighted(highlighted)

    if highlighted then
        self:setButtonState(ButtonItem.State.Highlighted)
    else
        self:setButtonState(ButtonItem.State.Default)
    end

    CollectionViewCell.setHighlighted(self, highlighted)
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function ButtonCollectionViewCell:setSelected(selected)
    if selected == self.selected then
        return false
    end

    self.textView:setSelected(selected)

    if selected then
        self:setButtonState(ButtonItem.State.Selected)
    else
        self:setButtonState(ButtonItem.State.Default)
    end

    CollectionViewCell.setSelected(self, selected)

    return true
end

return ButtonCollectionViewCell