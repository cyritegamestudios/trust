local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local WeaponSkillSettingsEditor = setmetatable({}, {__index = FFXIWindow })
WeaponSkillSettingsEditor.__index = WeaponSkillSettingsEditor


function WeaponSkillSettingsEditor.new(weaponSkills, trustSettings, helpUrl)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), WeaponSkillSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(20)

    self.weaponSkills = weaponSkills
    self.trustSettings = trustSettings
    self.helpUrl = helpUrl

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

    --self:setTitle("Edit weapon skills used in battle.")
end

function WeaponSkillSettingsEditor:onRemoveWeaponSkillClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local indexPath = selectedIndexPath
        if #self.weaponSkills > 1 then
            self.weaponSkills:remove(indexPath.row)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end
    end
end

function WeaponSkillSettingsEditor:onMoveWeaponSkillUp()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local indexPath = selectedIndexPath
        if #self.weaponSkills > 1 and indexPath.row > 1 then
            local newIndexPath = IndexPath.new(indexPath.section, indexPath.row - 1)
            local item1 = self:getDataSource():itemAtIndexPath(indexPath)
            local item2 = self:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self:getDataSource():swapItems(IndexedItem.new(item1, indexPath), IndexedItem.new(item2, newIndexPath))
                self:getDelegate():selectItemAtIndexPath(newIndexPath)
                self.weaponSkills[indexPath.row] = item2:getText()
                self.weaponSkills[indexPath.row - 1] = item1:getText()
            end
            self.trustSettings:saveSettings(true)
        end
    end
end

function WeaponSkillSettingsEditor:onMoveWeaponSkillDown()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local indexPath = selectedIndexPath
        if #self.weaponSkills > 1 and indexPath.row <= #self.weaponSkills then
            local newIndexPath = IndexPath.new(indexPath.section, indexPath.row + 1)
            local item1 = self:getDataSource():itemAtIndexPath(indexPath)
            local item2 = self:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self:getDataSource():swapItems(IndexedItem.new(item1, indexPath), IndexedItem.new(item2, newIndexPath))
                self:getDelegate():selectItemAtIndexPath(newIndexPath)
                self.weaponSkills[indexPath.row] = item2:getText()
                self.weaponSkills[indexPath.row + 1] = item1:getText()
            end
            self.trustSettings:saveSettings(true)
        end
    end
end

function WeaponSkillSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if L{'Add','H2H', 'Dagger', 'Sword', 'GreatSword', 'Axe', 'GreatAxe', 'Scythe', 'Polearm', 'Katana', 'GreatKatana', 'Club', 'Staff', 'Archery', 'Marksmanship'}:contains(textItem:getText()) then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            self.menuArgs['weapon_skills'] = self.weaponSkills
        end
    elseif textItem:getText() == 'Save' then
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Remove' then
        self:onRemoveWeaponSkillClick()
    elseif textItem:getText() == 'Move Up' then
        self:onMoveWeaponSkillUp()
    elseif textItem:getText() == 'Move Down' then
        self:onMoveWeaponSkillDown()
    elseif textItem:getText() == 'Help' then
        windower.open_url(self.helpUrl)
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

    local itemsToAdd = L{}

    local rowIndex = 1
    for weaponSkillName in L(self.weaponSkills):it() do
        itemsToAdd:append(IndexedItem.new(TextItem.new(weaponSkillName, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end


    --[[self.skillchains = T(self.trustSettings:getSettings())[self.settingsMode.value].Skillchains
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
    self.sectionMap[5] = self.skillchains.cleavews]]

    self:getDataSource():addItems(itemsToAdd)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
    end

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

return WeaponSkillSettingsEditor