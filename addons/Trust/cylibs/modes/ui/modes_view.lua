local Button = require('cylibs/ui/button')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Menu = require('cylibs/ui/menu/menu')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')
local ViewStack = require('cylibs/ui/views/view_stack')

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

    self:getDisposeBag():add(self.collectionView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local selectedModeName = modeNames[indexPath.row]
        if selectedModeName then
            self.collectionView:getDelegate():deselectItemAtIndexPath(indexPath)
            handle_cycle(selectedModeName)
            local oldItem = self.collectionView:getDataSource():itemAtIndexPath(indexPath)
            if oldItem then
                local newItem = TextItem.new(selectedModeName..': '..state[selectedModeName].value, oldItem:getStyle())
                self.collectionView:getDataSource():updateItem(newItem, indexPath)
            end
        end
    end), self.collectionView:getDelegate():didSelectItemAtIndexPath())

    return self
end

function ModesView:destroy()
    View.destroy(self)
end

function ModesView:layoutIfNeeded()
    self.collectionView:setPosition(0, 0)
    self.collectionView:setSize(self.frame.width, self.frame.height)

    self:setTitle("Change trust behavior with modes.")

    if not View.layoutIfNeeded(self) then
        return false
    end
end

function ModesView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        windower.send_command('trust save '..state.TrustMode.value)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll remember what to do.")
    end
end

return ModesView