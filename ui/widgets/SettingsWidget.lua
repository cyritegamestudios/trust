local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local SettingsWidget = setmetatable({}, {__index = Widget })
SettingsWidget.__index = SettingsWidget

function SettingsWidget.new(frame, addonSettings, trustMode, trustSettingsMode)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(14)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(Widget.new(frame, "Settings", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4), 45), SettingsWidget)

    self.trustMode = trustMode
    self.trustSettingsMode = trustSettingsMode

    for mode in L{ trustMode, trustSettingsMode }:it() do
        self:getDisposeBag():add(mode:on_state_change():addAction(function(_, new_value, old_value)
            if new_value ~= old_value then
                self:reloadSettings()
            end
        end), mode:on_state_change())
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()

        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            if indexPath.row == 1 then
                handle_cycle('TrustMode')
            else
                handle_cycle('MainTrustSettingsMode')
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:reloadSettings()

    self:setVisible(true)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SettingsWidget:reloadSettings()
    self:getDataSource():removeAllItems()

    local itemsToAdd = L{
        IndexedItem.new(TextItem.new(self.trustMode.value, TextStyle.Default.Subheadline), IndexPath.new(1, 1)),
        IndexedItem.new(TextItem.new(self.trustSettingsMode.value.." (DRK)", TextStyle.Default.Subheadline), IndexPath.new(1, 2))
    }

    self:getDataSource():addItems(itemsToAdd)
end

return SettingsWidget