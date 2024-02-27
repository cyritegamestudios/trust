local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local ScrollItem = require('ui/themes/ffxi/ScrollItem')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ModesView = setmetatable({}, {__index = FFXIWindow })
ModesView.__index = ModesView
ModesView.__type = "ModesView"


function ModesView.new(modeNames)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 10, 0, 0))), ModesView)

    self:setShouldRequestFocus(true)
    self:setScrollDelta(20)
    self:setScrollEnabled(true)

    local itemsToAdd = L{}

    local currentRow = 1
    for modeName in modeNames:it() do
        if state[modeName] then
            itemsToAdd:append(IndexedItem.new(TextItem.new(modeName..': '..state[modeName].value, TextStyle.Default.TextSmall), IndexPath.new(1, currentRow)))
            currentRow = currentRow + 1
        end
    end

    dataSource:addItems(itemsToAdd)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local selectedModeName = modeNames[indexPath.row]
        if selectedModeName then
            self:getDelegate():deselectItemAtIndexPath(indexPath)
            handle_cycle(selectedModeName)
            local oldItem = self:getDataSource():itemAtIndexPath(indexPath)
            if oldItem then
                local newItem = TextItem.new(selectedModeName..': '..state[selectedModeName].value, oldItem:getStyle())
                self:getDataSource():updateItem(newItem, indexPath)
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

return ModesView