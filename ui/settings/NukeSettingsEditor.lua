local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local spell_util = require('cylibs/util/spell_util')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local NukeSettingsEditor = setmetatable({}, {__index = FFXIWindow })
NukeSettingsEditor.__index = NukeSettingsEditor


function NukeSettingsEditor.new(trust, trustSettings, settingsMode, helpUrl)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageTextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), NukeSettingsEditor)

    self:setPadding(Padding.new(8, 0, 8, 0))
    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.helpUrl = helpUrl
    self.menuArgs = {}

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function NukeSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function NukeSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit spells used to magic burst and free nuke.")
end

function NukeSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Edit' then
        self.menuArgs['spells'] = self.spells or L{}
    elseif textItem:getText() == 'Help' then
        windower.open_url(self.helpUrl)
    end
end

function NukeSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function NukeSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function NukeSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    self.spells = L(T(self.trustSettings:getSettings())[self.settingsMode.value].NukeSettings.Spells)

    local rowIndex = 1
    for spell in self.spells:it() do
        local textItem = TextItem.new(spell:get_spell().en, TextStyle.Default.PickerItem)
        textItem:setLocalizedText(spell:get_localized_name())
        local imageItem = AssetManager.imageItemForSpell(spell:get_name())
        items:append(IndexedItem.new(ImageTextItem.new(imageItem, textItem), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    self:layoutIfNeeded()
end

return NukeSettingsEditor