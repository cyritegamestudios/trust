local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local PullSettingsEditor = setmetatable({}, {__index = FFXIWindow })
PullSettingsEditor.__index = PullSettingsEditor


function PullSettingsEditor.new(addon_settings, puller)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.ConfigEditor, 10), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), PullSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.addon_settings = addon_settings
    self.puller = puller

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PullSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function PullSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Choose mobs to pull.")
end

function PullSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function PullSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local allTargets = (self.addon_settings:getSettings().battle.targets or L{}):sort()

    local items = L{}
    local rowIndex = 1

    for targetName in allTargets:it() do
        local indexPath = IndexPath.new(1, rowIndex)
        items:append(IndexedItem.new(TextItem.new(targetName, TextStyle.PickerView.Text), indexPath))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function PullSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Remove' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            local targetsToRemove = L{}
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    targetsToRemove:append(item:getText())
                end
            end
            local targets = S(self.addon_settings:getSettings().battle.targets):filter(function(targetName) return not targetsToRemove:contains(targetName) end)

            self.addon_settings:getSettings().battle.targets = L(targets)
            self.addon_settings:saveSettings()

            if self.puller then
                self.puller:set_target_names(targets)
            end

            self:getDelegate():deselectAllItems()
            self:getDataSource():removeItems(selectedIndexPaths)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't pull these mobs anymore.")
        end
    end
end

return PullSettingsEditor