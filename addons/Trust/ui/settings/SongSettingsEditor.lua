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

local SongSettingsEditor = setmetatable({}, {__index = CollectionView })
SongSettingsEditor.__index = SongSettingsEditor


function SongSettingsEditor.new(trustSettings, settingsMode, width)
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

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0)), nil, selectionImageItem), SongSettingsEditor)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.menuArgs = {}

    self.allSongs = spell_util.get_spells(function(spell)
        return spell.type == 'BardSong'
    end)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SongSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function SongSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit songs on the player and party.")
end

function SongSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Edit' then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            local indexPath = selectedIndexPaths[1]
            if indexPath.section == 1 then
                self.menuArgs['help_text'] = "Choose 3 dummy songs."
                self.menuArgs['songs'] = self.dummySongs
                self.menuArgs['validator'] = function(songNames)
                    local buffsForDummySongs = S(songNames:map(function(songName)
                        local spellId = spell_util.spell_id(songName)
                        return buff_util.buff_for_spell(spellId).id
                    end))
                    if buffsForDummySongs:length() ~= 3 then
                        return "You must choose 3 dummy songs."
                    end
                    local buffsForSongs = S(self.songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))
                    if set.intersection(buffsForDummySongs, buffsForSongs):length() > 0 then
                        return "Dummy songs cannot give the same status effects as real songs."
                    end
                    return nil
                end
            elseif indexPath.section == 2 then
                self.menuArgs['help_text'] = "Choose 5 songs."
                self.menuArgs['songs'] = self.songs
                self.menuArgs['validator'] = function(songNames)
                    if songNames:length() ~= 5 then
                        return "You must choose 5 songs."
                    end
                    return nil
                end
            end
        end
    elseif textItem:getText() == 'Help' then
        windower.open_url(settings.help.wiki_base_url..'/Singer')
    end
end

function SongSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function SongSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function SongSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    self.dummySongs = L(T(self.trustSettings:getSettings())[self.settingsMode.value].DummySongs)
    self.songs = L(T(self.trustSettings:getSettings())[self.settingsMode.value].Songs)

    local rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Dummy Songs", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    rowIndex = rowIndex + 1
    for song in self.dummySongs:it() do
        items:append(IndexedItem.new(TextItem.new(song:get_spell().name, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Songs", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))
    rowIndex = rowIndex + 1
    for song in self.songs:it() do
        items:append(IndexedItem.new(TextItem.new(song:get_spell().name, TextStyle.Default.TextSmall), IndexPath.new(2, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 2))
end

return SongSettingsEditor