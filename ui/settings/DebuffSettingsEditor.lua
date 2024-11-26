local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local DebuffSettingsEditor = setmetatable({}, {__index = FFXIWindow })
DebuffSettingsEditor.__index = DebuffSettingsEditor


function DebuffSettingsEditor.new(trust, trustSettings, settingsMode, helpUrl)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageTextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), DebuffSettingsEditor)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.helpUrl = helpUrl

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self:reloadSettings()

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    return self
end

function DebuffSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function DebuffSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit debuffs on the party's battle target.")
end

function DebuffSettingsEditor:onEditSpellClick(indexPath)
    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        local spellSettings = self.selfSpells[selectedIndexPaths[1].row]
        if spellSettings then
            local spellSettingsEditor = SpellSettingsEditor.new(spellSettings, self.actionsMenu, 300)

            spellSettingsEditor:setSize(300, 300)
            spellSettingsEditor:setPosition(100, 100)
            spellSettingsEditor:setVisible(true)

            spellSettingsEditor:setNeedsLayout()
            spellSettingsEditor:layoutIfNeeded()
        end
    end
end

function DebuffSettingsEditor:onRemoveSpellClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        -- TODO: remove spell from trustSettings as well
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.selfSpells:remove(indexPath.row)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end

    end
end

function DebuffSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        -- TODO: uncomment when saving legacy settings is implemented
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Remove' then
        self:onRemoveSpellClick()
    elseif textItem:getText() == 'Help' then
        windower.open_url(self.helpUrl)
    end
end

function DebuffSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function DebuffSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    self.selfSpells = L(T(self.trustSettings:getSettings())[self.settingsMode.value].Debuffs)

    local rowIndex = 1
    for spell in self.selfSpells:it() do
        local textItem = TextItem.new(spell:get_spell().en, TextStyle.Default.PickerItem)
        textItem:setLocalizedText(spell:get_localized_name())
        local imageItem = AssetManager.imageItemForSpell(spell:get_name())
        items:append(IndexedItem.new(ImageTextItem.new(imageItem, textItem), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if items:length() > 0 then
        self:getDelegate():selectItemAtIndexPath(items[1]:getIndexPath())
    end

    self:layoutIfNeeded()
end

return DebuffSettingsEditor