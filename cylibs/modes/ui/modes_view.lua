local Button = require('cylibs/ui/button')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
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

local ModesView = setmetatable({}, {__index = CollectionView })
ModesView.__index = ModesView
ModesView.__type = "ModesView"


function ModesView.new(modeNames)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0)), nil, cursorImageItem), ModesView)

    self:setShouldRequestFocus(true)
    self:setScrollDelta(20)

    local itemsToAdd = L{}

    local currentRow = 1
    for modeName in modeNames:it() do
        itemsToAdd:append(IndexedItem.new(TextItem.new(modeName..': '..state[modeName].value, TextStyle.Default.TextSmall), IndexPath.new(1, currentRow)))
        currentRow = currentRow + 1
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

function ModesView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("Change trust behavior with modes.")
end

function ModesView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        windower.send_command('trust save '..state.TrustMode.value)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll remember what to do.")
    end
end

return ModesView