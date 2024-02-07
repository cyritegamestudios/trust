local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local BloodPactSettingsEditor = setmetatable({}, {__index = CollectionView })
BloodPactSettingsEditor.__index = BloodPactSettingsEditor


function BloodPactSettingsEditor.new(trustSettings, bloodPacts)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0)), nil, cursorImageItem), BloodPactSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(20)

    self.trustSettings = trustSettings
    self.bloodPacts = bloodPacts

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function BloodPactSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function BloodPactSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Choose Blood Pact: Wards to buff the party with.")
end

function BloodPactSettingsEditor:onRemoveJobAbilityClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.jobAbilities:remove(indexPath.row - 1)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end
    end
end

function BloodPactSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Remove' then
        self:onRemoveJobAbilityClick()
    end
end

function BloodPactSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function BloodPactSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function BloodPactSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1

    for bloodPact in self.bloodPacts:it() do
        items:append(IndexedItem.new(TextItem.new(bloodPact:get_job_ability_name(), TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self.bloodPacts:length() > 0 then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
    end
end

return BloodPactSettingsEditor