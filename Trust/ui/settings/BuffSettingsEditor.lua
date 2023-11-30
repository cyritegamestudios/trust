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

local BuffSettingsEditor = setmetatable({}, {__index = CollectionView })
BuffSettingsEditor.__index = BuffSettingsEditor


function BuffSettingsEditor.new(trustSettings, settingsMode, width)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        if indexPath.row ~= 1 then
            cell:setUserInteractionEnabled(true)
        end
        return cell
    end)

    local selectionImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', width / 4, 20)
    selectionImageItem:setAlpha(125)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0)), nil, selectionImageItem), BuffSettingsEditor)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.menuArgs = {}

    self.allBuffs = spell_util.get_spells(function(spell)
        return spell.status ~= nil and S{'Self', 'Party'}:intersection(S(spell.targets)):length() > 0
    end)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function BuffSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function BuffSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit buffs on the player and party.")
end

function BuffSettingsEditor:onRemoveSpellClick()
    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        -- TODO: remove spell from trustSettings as well
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPaths[1])
        if item then
            local indexPath = selectedIndexPaths[1]
            if indexPath.section == 1 then
                self.selfSpells:remove(indexPath.row - 1)
            elseif indexPath.section == 2 then
                self.partySpells:remove(indexPath.row - 1)
            end

            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end

    end
end

function BuffSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        -- TODO: uncomment when saving legacy settings is implemented
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Add' then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            local indexPath = selectedIndexPaths[1]
            if indexPath.section == 1 then
                self.menuArgs['spells'] = self.selfSpells
                self.menuArgs['targets'] = S{'Self', 'Party'}
            elseif indexPath.section == 2 then
                self.menuArgs['spells'] = self.partySpells
                self.menuArgs['targets'] = S{'Party'}
            end
        else
            self.menuArgs['spells'] = self.selfSpells
            self.menuArgs['targets'] = S{'Self', 'Party'}
        end
    elseif textItem:getText() == 'Edit' then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            local indexPath = selectedIndexPaths[1]
            if indexPath.section == 1 then
                self.menuArgs['spell'] = self.selfSpells[indexPath.row - 1]
            elseif indexPath.section == 2 then
                self.menuArgs['spell'] = self.partySpells[indexPath.row - 1]
            end
        end
    elseif textItem:getText() == 'Remove' then
        self:onRemoveSpellClick()
    end
end

function BuffSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function BuffSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function BuffSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    self.selfSpells = L(T(self.trustSettings:getSettings())[self.settingsMode.value].SelfBuffs)
    self.partySpells = L(T(self.trustSettings:getSettings())[self.settingsMode.value].PartyBuffs)

    local rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Buffs on self", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    rowIndex = rowIndex + 1
    for spell in self.selfSpells:it() do
        items:append(IndexedItem.new(TextItem.new(spell:get_spell().name, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Buffs on party", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))
    rowIndex = rowIndex + 1
    for spell in self.partySpells:it() do
        items:append(IndexedItem.new(TextItem.new(spell:get_spell().name, TextStyle.Default.TextSmall), IndexPath.new(2, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self.selfSpells:length() > 0 then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 2))
    elseif self.partySpells:length() > 0 then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(2, 2))
    end
end

return BuffSettingsEditor