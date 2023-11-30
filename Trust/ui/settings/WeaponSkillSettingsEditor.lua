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

local WeaponSkillSettingsEditor = setmetatable({}, {__index = CollectionView })
WeaponSkillSettingsEditor.__index = WeaponSkillSettingsEditor


function WeaponSkillSettingsEditor.new(trustSettings, settingsMode, width)
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

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0)), nil, selectionImageItem), WeaponSkillSettingsEditor)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.menuArgs = {}

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function WeaponSkillSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function WeaponSkillSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit weapon skills used in battle.")
end

function WeaponSkillSettingsEditor:onRemoveWeaponSkillClick()
    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        local indexPath = selectedIndexPaths[1]
        local weaponSkills = self.sectionMap[indexPath.section]
        if #weaponSkills > 1 then
            weaponSkills:remove(indexPath.row - 1)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(false)
        end
    end
end

function WeaponSkillSettingsEditor:onMoveWeaponSkillUp()
    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        local indexPath = selectedIndexPaths[1]
        local weaponSkills = self.sectionMap[indexPath.section]
        if #weaponSkills > 1 and indexPath.row > 2 then
            local newIndexPath = IndexPath.new(indexPath.section, indexPath.row - 1)
            local item1 = self:getDataSource():itemAtIndexPath(indexPath)
            local item2 = self:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self:getDataSource():swapItems(IndexedItem.new(item1, indexPath), IndexedItem.new(item2, newIndexPath))
                self:getDelegate():selectItemAtIndexPath(newIndexPath)
                local item = weaponSkills:remove(newIndexPath.row)
                weaponSkills:insert(newIndexPath.row - 1, item)
            end
            self.trustSettings:saveSettings(false)
        end
    end
end

function WeaponSkillSettingsEditor:onMoveWeaponSkillDown()
    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        local indexPath = selectedIndexPaths[1]
        local weaponSkills = self.sectionMap[indexPath.section]
        if #weaponSkills > 1 and indexPath.row <= #weaponSkills then
            local newIndexPath = IndexPath.new(indexPath.section, indexPath.row + 1)
            local item1 = self:getDataSource():itemAtIndexPath(indexPath)
            local item2 = self:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self:getDataSource():swapItems(IndexedItem.new(item1, indexPath), IndexedItem.new(item2, newIndexPath))
                self:getDelegate():selectItemAtIndexPath(newIndexPath)
                local item = weaponSkills:remove(indexPath.row - 1)
                weaponSkills:insert(indexPath.row, item)
            end
            self.trustSettings:saveSettings(false)
        end
    end
end

function WeaponSkillSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if L{'Add', 'H2H', 'Dagger', 'Sword', 'GreatSword', 'Axe', 'GreatAxe', 'Scythe', 'Polearm', 'Katana', 'GreatKatana', 'Club', 'Staff', 'Archery', 'Marksmanship'}:contains(textItem:getText()) then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            local indexPath = selectedIndexPaths[1]
            self.menuArgs['weapon_skills'] = self.sectionMap[indexPath.section]
        end
    elseif textItem:getText() == 'Save' then
        self.trustSettings:saveSettings(false)
    elseif textItem:getText() == 'Remove' then
        self:onRemoveWeaponSkillClick()
    elseif textItem:getText() == 'Move Up' then
        self:onMoveWeaponSkillUp()
    elseif textItem:getText() == 'Move Down' then
        self:onMoveWeaponSkillDown()
    elseif textItem:getText() == 'Help' then
        windower.open_url(settings.help.wiki_base_url..'/Skillchainer')
    end
end

function WeaponSkillSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function WeaponSkillSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function WeaponSkillSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    self.skillchains = T(self.trustSettings:getSettings())[self.settingsMode.value].Skillchains
    self.sectionMap = {}

    local rowIndex = 1

    -- Default
    items:append(IndexedItem.new(TextItem.new("Use these weapon skills first", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    rowIndex = 2
    for weaponSkillName in L(self.skillchains.defaultws):it() do
        items:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end
    self.sectionMap[1] = self.skillchains.defaultws

    -- Spam
    items:append(IndexedItem.new(TextItem.new("Use these weapon skills when spamming", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))
    rowIndex = 2
    for weaponSkillName in L(self.skillchains.spamws):it() do
        items:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(2, rowIndex)))
        rowIndex = rowIndex + 1
    end
    self.sectionMap[2] = self.skillchains.spamws

    -- Starter
    items:append(IndexedItem.new(TextItem.new("Use these weapon skills when opening", TextStyle.Default.HeaderSmall), IndexPath.new(3, 1)))
    rowIndex = 2
    for weaponSkillName in L(self.skillchains.starterws):it() do
        items:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(3, rowIndex)))
        rowIndex = rowIndex + 1
    end
    self.sectionMap[3] = self.skillchains.starterws

    -- Prefer
    items:append(IndexedItem.new(TextItem.new("Prioritize these weapon skills", TextStyle.Default.HeaderSmall), IndexPath.new(4, 1)))
    rowIndex = 2
    for weaponSkillName in L(self.skillchains.preferws):it() do
        items:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(4, rowIndex)))
        rowIndex = rowIndex + 1
    end
    self.sectionMap[4] = self.skillchains.preferws

    -- Cleave
    items:append(IndexedItem.new(TextItem.new("Use these weapon skills when cleaving", TextStyle.Default.HeaderSmall), IndexPath.new(5, 1)))
    rowIndex = 2
    for weaponSkillName in L(self.skillchains.cleavews):it() do
        items:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(5, rowIndex)))
        rowIndex = rowIndex + 1
    end
    self.sectionMap[5] = self.skillchains.cleavews

    self:getDataSource():addItems(items)

    if items:length() > 1 then
        self:getDelegate():selectItemAtIndexPath(items[2]:getIndexPath())
    end
end

return WeaponSkillSettingsEditor