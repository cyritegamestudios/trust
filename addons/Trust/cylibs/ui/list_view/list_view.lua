local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local ListView = setmetatable({}, {__index = CollectionView })
ListView.__index = ListView

---
-- Creates a new ListView with the given items and layout.
--
-- @tparam table items A table containing items to be displayed in the ListView.
-- @tparam Layout layout The layout to be used for the ListView.
-- @tparam number itemSize The width or height of the item.
-- @treturn ListView The created ListView.
--
function ListView.new(items, layout, itemSize)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(itemSize or 40)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, layout), ListView)

    local rowIndex = 1
    for item in items:it() do
        self:getDataSource():addItem(item, IndexPath.new(1, rowIndex))
    end

    return self
end

---
-- Creates a horizontal ListView with the given text.
--
-- @tparam list strings A table containing text strings to be displayed in each row.
-- @tparam TextStyle style (Optional) The style to be applied to the text items.
-- @tparam number textWidth (Optional) The width of the text.
-- @treturn ListView The created horizontal ListView.
--
function ListView.horizontalList(strings, style, textWidth)
    local style = style or TextStyle.Default.Text
    local items = strings:map(function(string) return TextItem.new(string, style)  end):reverse()
    local listView = ListView.new(items, HorizontalFlowLayout.new(2), textWidth)
    return listView
end

---
-- Creates a vertical ListView with the given text.
--
-- @tparam table strings A table containing text strings to be displayed in each row.
-- @tparam TextStyle style (Optional) The style to be applied to the text items.
-- @tparam number textHeight (Optional) The height of the text.
-- @treturn ListView The created horizontal ListView.
--
function ListView.verticalList(strings, style, textHeight)
    local style = style or TextStyle.Default.Text
    local items = strings:map(function(string) return TextItem.new(string, style)  end):reverse()
    local listView = ListView.new(items, VerticalFlowLayout.new(2, Padding.new(0, 10, 0, 0)), textHeight)
    return listView
end

return ListView