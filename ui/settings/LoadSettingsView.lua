local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local LoadSettingsView = setmetatable({}, {__index = FFXIWindow })
LoadSettingsView.__index = LoadSettingsView


function LoadSettingsView.new(jobSettingsMode, addonSettings, trustModeSettings)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), LoadSettingsView)

    self.addonSettings = addonSettings
    self.trustModeSettings = trustModeSettings

    self:setAllowsMultipleSelection(false)
    self:setScrollDelta(20)
    self:setScrollEnabled(true)

    local itemsToAdd = L{}
    local itemsToSelect = L{}

    local trustMode = state['TrustMode']

    local rowIndex = 1
    for _, v in ipairs(trustMode) do
        local item = TextItem.new(tostring(v), TextStyle.Default.TextSmall)
        local indexPath = IndexPath.new(1, rowIndex)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        if item:getText() == trustMode.value then
            itemsToSelect:append(indexPath)
        end
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(itemsToAdd)

    for indexPath in itemsToSelect:it() do
        self:getDelegate():selectItemAtIndexPath(indexPath)
    end

    local updateSelectedItems = function(section, selectedItem)
        for row = 1, self:getDataSource():numberOfItemsInSection(section) do
            local indexPath = IndexPath.new(1, row)
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            if item and item:getText() ~= selectedItem:getText() then
                --self:getDelegate():deselectItemAtIndexPath(indexPath)
            end
        end
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            updateSelectedItems(1, item)
            handle_set('TrustMode', item:getText())
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function LoadSettingsView:destroy()
    FFXIWindow.destroy(self)
end

function LoadSettingsView:layoutIfNeeded()
    if not FFXIWindow.layoutIfNeeded(self) then
        return false
    end
    self:setTitle("Load saved mode sets.")
end

function LoadSettingsView:deleteModeSet(modeSetName)
    if self.trustModeSettings:getSettings()[modeSetName] then
        self.trustModeSettings:deleteSettings(modeSetName)
        addon_message(260, '('..windower.ffxi.get_player().name..') '..modeSetName.."? What "..modeSetName.."?")
    end
end

function LoadSettingsView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Delete' then
        local selectedIndexPath = L(self:getDelegate():getSelectedIndexPaths())[1]
        if selectedIndexPath then
            local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item:getText() ~= 'Default' then
                self:deleteModeSet(item:getText())
                self:getDataSource():removeItem(selectedIndexPath)
                self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
            else
                addon_message(260, '('..windower.ffxi.get_player().name..") I can't forget Default!")
            end
        end
    end
end

return LoadSettingsView