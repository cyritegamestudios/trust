local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ListView = require('cylibs/ui/list_view/list_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')
local spell_util = require('cylibs/util/spell_util')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustSettingsLoader = require('TrustSettings')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local LoadSettingsView = setmetatable({}, {__index = CollectionView })
LoadSettingsView.__index = LoadSettingsView


function LoadSettingsView.new()
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), LoadSettingsView)



    local itemsToAdd = L{}

    itemsToAdd:append(IndexedItem.new(TextItem.new("Load mode set", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))

    local trustMode = state['TrustMode']

    local rowIndex = 2
    for _, v in ipairs(trustMode) do
        local item = TextItem.new(tostring(v), TextStyle.Default.TextSmall)
        local indexPath = IndexPath.new(1, rowIndex)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        rowIndex = rowIndex + 1
    end

    itemsToAdd:append(IndexedItem.new(TextItem.new("Load job settings", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))

    local jobSettingsMode = state['MainTrustSettingsMode']

    rowIndex = 2
    for _, v in ipairs(jobSettingsMode) do
        local item = TextItem.new(tostring(v), TextStyle.Default.TextSmall)
        local indexPath = IndexPath.new(2, rowIndex)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(itemsToAdd)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            if indexPath.section == 1 then
                handle_set('TrustMode', item:getText())
            elseif indexPath.section == 2 then
                handle_set('MainTrustSettingsMode', item:getText())
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function LoadSettingsView:destroy()
    CollectionView.destroy(self)
end

function LoadSettingsView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Load trust modes and job settings.")
end

return LoadSettingsView