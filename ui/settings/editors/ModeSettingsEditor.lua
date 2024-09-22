local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ModesView = setmetatable({}, {__index = FFXIWindow })
ModesView.__index = ModesView
ModesView.__type = "ModesView"


function ModesView.new(modeNames, infoView, modes)
    local layoutParams = FFXIWindow.getLayoutParams(
            15,
            16,
            2,
            FFXIClassicStyle.WindowSize.Editor.ConfigEditor,
            FFXIClassicStyle.Padding.ConfigEditor
    )

    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    modes = modes or state
    modeNames = modeNames:filter(function(modeName) return modes[modeName] ~= nil end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, layoutParams.padding), nil, false, layoutParams.viewSize), ModesView)

    self.modes = modes
    self:setShouldRequestFocus(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    local itemsToAdd = L{}

    local currentRow = 1
    for modeName in modeNames:it() do
        if modes[modeName] then
            itemsToAdd:append(IndexedItem.new(TextItem.new(modeName..': '..modes[modeName].value, TextStyle.Default.TextSmall), IndexPath.new(1, currentRow)))
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
                local newItem = TextItem.new(selectedModeName..': '..modes[selectedModeName].value, oldItem:getStyle())
                self:setDescription(selectedModeName, infoView)
                self:getDataSource():updateItem(newItem, indexPath)
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        local selectedModeName = modeNames[indexPath.row]
        if selectedModeName then
            self:setDescription(selectedModeName, infoView)
        end
    end), self:getDelegate():didMoveCursorToItemAtIndexPath())

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function ModesView:setDescription(modeName, infoView)
    if not infoView then
        return
    end
    local description = self.modes[modeName]:get_description(self.modes[modeName].value) or "View and change Trust modes."
    description = string.gsub(description, "^Okay, ", "")
    description = description:gsub("^%l", string.upper)
    infoView:setDescription(description)
end

return ModesView