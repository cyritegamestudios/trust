local Button = require('cylibs/ui/button')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local ModesView = setmetatable({}, {__index = View })
ModesView.__index = ModesView
ModesView.__type = "ModesView"

function ModesView.new(modeNames)
    local self = setmetatable(View.new(), ModesView)

    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    self.collectionView = CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0)))

    self:addSubview(self.collectionView)

    local itemsToAdd = L{}

    local currentRow = 1
    for modeName in modeNames:it() do
        itemsToAdd:append(IndexedItem.new(TextItem.new(modeName..': '..state[modeName].value, TextStyle.Default.TextSmall), IndexPath.new(1, currentRow)))
        currentRow = currentRow + 1
    end

    dataSource:addItems(itemsToAdd)

    self:getDisposeBag():add(self.collectionView:getDelegate():didSelectItemAtIndexPath():addAction(function(item, indexPath)
        local selectedModeName = modeNames[indexPath.row]
        if selectedModeName then
            self.collectionView:getDelegate():deselectItemAtIndexPath(item, indexPath)
            handle_cycle(selectedModeName)
            local newItem = TextItem.new(selectedModeName..': '..state[selectedModeName].value, item:getStyle())
            self.collectionView:getDataSource():updateItem(newItem, indexPath)
        end
    end), self.collectionView:getDelegate():didSelectItemAtIndexPath())

    self.saveButton = Button.new(string.upper("save"), 60, 25)

    self:addSubview(self.saveButton)

    self:getDisposeBag():add(self.saveButton:onClick():addAction(function(_, x, y)
        windower.send_command('trust save '..state.TrustMode.value)
    end), self.saveButton:onClick())

    return self
end

function ModesView:layoutIfNeeded()
    self.collectionView:setPosition(0, 0)
    self.collectionView:setSize(self.frame.width, self.frame.height)

    self.saveButton:setPosition(self.frame.width - self.saveButton.frame.width - 45, 5)

    if not View.layoutIfNeeded(self) then
        return false
    end
end

return ModesView