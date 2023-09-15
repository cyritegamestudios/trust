local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local PickerView = setmetatable({}, {__index = CollectionView })
PickerView.__index = PickerView

TextStyle.PickerView = {
    Text = TextStyle.new(
            Color.white:withAlpha(50),
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.lightGrey,
            0,
            0,
            0,
            false
    ),
}

function PickerView.new(items, frame)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(0, 5, 0, 0))), PickerView)

    self.allowsMultipleSelection = true

    self:setPosition(frame.x, frame.y)
    self:setSize(frame.width, frame.height)
    self:setScrollEnabled(true)
    self:setScrollDelta(20)

    self.bgView = BackgroundView.new(frame,
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

    self:addSubview(self.bgView)

    self.bgView:setVisible(true)
    self.bgView:setNeedsLayout()
    self.bgView:layoutIfNeeded()

    local indexedItems = L{}

    local rowIndex = 1
    for item in items:it() do
        indexedItems:append(IndexedItem.new(item, IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    dataSource:addItems(indexedItems)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Creates a PickerView with the given text items, frame, and style.
--
-- @tparam list texts A list of text strings to be displayed in each row.
-- @tparam Frame frame The frame of the PickerView.
-- @tparam[opt] TextStyle style The text style to be applied to the items.
-- @treturn PickerView The created PickerView.
--
function PickerView.withTextItems(texts, frame, style)
    local style = style or TextStyle.PickerView.Text
    local items = texts:map(function(string) return TextItem.new(string, style)  end)
    return PickerView.new(items, frame)
end

---
-- Destroys the PickerView.
--
function PickerView:destroy()
    CollectionView.destroy(self)
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function PickerView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    if self.bgView then
        self.bgView:setVisible(self:isVisible())
        self.bgView:setSize(self.frame.width, self.frame.height)
        self.bgView:setVisible(self:isVisible())
    end

    return true
end

return PickerView