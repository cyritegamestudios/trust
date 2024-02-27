local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local spell_util = require('cylibs/util/spell_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local NukeSettingsEditor = setmetatable({}, {__index = FFXIWindow })
NukeSettingsEditor.__index = NukeSettingsEditor


function NukeSettingsEditor.new(trustSettings, settingsMode, helpUrl)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), NukeSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(20)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.helpUrl = helpUrl
    self.menuArgs = {}

    self.allSpells = spell_util.get_spells(function(spell)
        return spell.type == 'BlackMagic'
    end)

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
        items:append(IndexedItem.new(TextItem.new(spell:get_spell().en, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

return NukeSettingsEditor