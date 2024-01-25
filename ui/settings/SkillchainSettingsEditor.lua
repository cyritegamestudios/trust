local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local config = require('config')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local SkillchainSettingsEditor = setmetatable({}, {__index = CollectionView })
SkillchainSettingsEditor.__index = SkillchainSettingsEditor


function SkillchainSettingsEditor.new(weaponSkillSettings, abilities)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0)), nil, cursorImageItem), SkillchainSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(20)

    self.weaponSkillSettings = weaponSkillSettings
    self.abilities = abilities
    self.menuArgs = {}

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(state.WeaponSkillSettingsMode:on_state_change():addAction(function(_, new_value)
        self.abilities = self.weaponSkillSettings:getSettings()[new_value].Skillchain
        self:reloadSettings()
    end), state.WeaponSkillSettingsMode:on_state_change())

    return self
end

function SkillchainSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function SkillchainSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Specify one or more steps of the skillchain.")
end

function SkillchainSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function SkillchainSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local skillchain_builder = SkillchainBuilder.new(self.abilities:filter(function(ability) return not L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(ability:get_name()) end))

    local items = L{}

    for rowIndex = 1, 6 do
        local ability = self.abilities[rowIndex]
        if not ability then
            ability = SkillchainAbility.auto()
        end
        local indexPath = IndexPath.new(1, rowIndex)
        local text = 'Step '..rowIndex..': '..ability:get_name()
        if rowIndex > 1 then
            local skillchain = skillchain_builder:reduce_skillchain(self.abilities:slice(1, rowIndex))
            if skillchain then
                text = text..' ('..skillchain:get_name()..')'
            end
        end
        items:append(IndexedItem.new(TextItem.new(text, TextStyle.Default.TextSmall), indexPath))
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function SkillchainSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Edit' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuArgs['selected_index'] = cursorIndexPath.row
        end
    elseif textItem:getText() == 'Clear' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                local indexPath = cursorIndexPath
                self.abilities[indexPath.row] = SkillchainAbility.auto()
                self.weaponSkillSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll figure out what to use on my own for Step "..indexPath.row.."!")

                self:reloadSettings()
            end
        end
    elseif textItem:getText() == 'Skip' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                local indexPath = cursorIndexPath
                self.abilities[indexPath.row] = SkillchainAbility.skip()
                self.weaponSkillSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll let a party member take care of Step "..indexPath.row.."!")

                self:reloadSettings()
            end
        end
    elseif textItem:getText() == 'Clear All' then
        self.abilities:clear()
        for _ = 1, 6 do
            self.abilities:append(SkillchainAbility.auto())
        end
        self.weaponSkillSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, back to the drawing board!")

        self:reloadSettings()
    elseif textItem:getText() == 'Change Set' then
        handle_cycle('WeaponSkillSettingsMode')
    end
end

function SkillchainSettingsEditor:getMenuArgs()
    return self.menuArgs
end

return SkillchainSettingsEditor