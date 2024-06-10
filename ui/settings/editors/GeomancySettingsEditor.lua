local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local GeomancySettingsEditor = setmetatable({}, {__index = FFXIWindow })
GeomancySettingsEditor.__index = GeomancySettingsEditor


function GeomancySettingsEditor.new(trustSettings, spells, targets)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.ConfigEditor), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), GeomancySettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)

    self.trustSettings = trustSettings
    self.spells = spells or L{}
    self.targets = targets
    self.menuArgs = {}

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function GeomancySettingsEditor:destroy()
    CollectionView.destroy(self)
end

function GeomancySettingsEditor:getMenuArgs()
    return self.menuArgs
end

function GeomancySettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function GeomancySettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1
    for spell in self.spells:it() do
        local text = spell:get_spell().en
        if spell:get_target() then
            text = text..' → '..spell:get_target()
            local target = windower.ffxi.get_mob_by_target(spell:get_target())
            if target then
                text = text..' ('..target.name..')'
            end
        end
        items:append(IndexedItem.new(TextItem.new(text, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function GeomancySettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Targets' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuArgs['spell'] = self.spells[cursorIndexPath.row]
        end
    elseif textItem:getText() == 'Remove' then
        self:onRemoveSpellClick()
    end
end

function GeomancySettingsEditor:onRemoveSpellClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.spells:remove(indexPath.row)
            self:getDataSource():removeItem(indexPath)

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I wont entrust "..item:getText().." anymore.")
        end
    end
end

return GeomancySettingsEditor