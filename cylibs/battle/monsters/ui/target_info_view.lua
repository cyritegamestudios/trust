local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local spell_util = require('cylibs/util/spell_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local TargetInfoView = setmetatable({}, {__index = FFXIWindow })
TargetInfoView.__index = TargetInfoView


function TargetInfoView.new(target)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setIsSelectable(false)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, FFXIClassicStyle.Padding.ConfigEditor, 6), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), TargetInfoView)

    self.target = target

    self:setShouldRequestFocus(true)
    --self:setAllowsCursorSelection(false)
    self:setScrollDelta(16)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function TargetInfoView:destroy()
    CollectionView.destroy(self)
end

function TargetInfoView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit spells used to magic burst and free nuke.")
end

function TargetInfoView:reloadSettings()
    self:getDataSource():removeAllItems()

    local itemsToAdd = L{}

    -- Target Name
    local targetNameHeaderItem = SectionHeaderItem.new(
            TextItem.new("Target Name", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(1, targetNameHeaderItem)

    itemsToAdd:append(IndexedItem.new(TextItem.new(self.target:get_name(), TextStyle.Default.TextSmall), IndexPath.new(1, 1)))

    -- Target ID
    local targetIdHeaderItem = SectionHeaderItem.new(
            TextItem.new("Target ID", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(2, targetIdHeaderItem)

    itemsToAdd:append(IndexedItem.new(TextItem.new(self.target:get_id(), TextStyle.Default.TextSmall), IndexPath.new(2, 1)))

    -- Target claimed by
    local targetClaimHeaderItem = SectionHeaderItem.new(
            TextItem.new("Claimed By", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(3, targetClaimHeaderItem)

    local claimedBy = "Unclaimed"
    if self.target:get_mob().claim_id and windower.ffxi.get_mob_by_id(self.target:get_mob().claim_id) then
        claimedBy = windower.ffxi.get_mob_by_id(self.target:get_mob().claim_id).name
    end

    itemsToAdd:append(IndexedItem.new(TextItem.new(claimedBy, TextStyle.Default.TextSmall), IndexPath.new(3, 1)))

    -- Target Debuffs
    local targetDebuffsHeaderItem = SectionHeaderItem.new(
            TextItem.new("Debuffs", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(4, targetDebuffsHeaderItem)

    local debuffNames = L(self.target.debuff_tracker:get_debuff_ids():map(function(debuff_id) return buff_util.buff_name(debuff_id) end)):compact_map()
    if debuffNames:empty() then
        debuffNames = L{ "None" }
    end

    itemsToAdd:append(IndexedItem.new(TextItem.new(localization_util.commas(debuffNames, "and"), TextStyle.Default.TextSmall), IndexPath.new(4, 1)))

    self:getDataSource():addItems(itemsToAdd)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    self:layoutIfNeeded()
end

function TargetInfoView:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

return TargetInfoView