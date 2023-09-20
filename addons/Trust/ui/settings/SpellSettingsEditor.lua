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
local spell_util = require('cylibs/util/spell_util')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustSettingsLoader = require('TrustSettings')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local SpellSettingsEditor = setmetatable({}, {__index = CollectionView })
SpellSettingsEditor.__index = SpellSettingsEditor


function SpellSettingsEditor.new(spellSettings, actionsMenu, width)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    -- type
    -- job names
    -- job abilities
    -- conditions

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), SpellSettingsEditor)

    self.spellSettings = spellSettings
    self.actionsMenu = actionsMenu

    local backgroundView = BackgroundView.new(Frame.new(0, 0, 300, 300),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

    self:setBackgroundImageView(backgroundView)

    local items = L{}

    items:append(IndexedItem.new(TextItem.new(spellSettings['type'], TextStyle.Default.TextSmall), IndexPath.new(1, 1)))
    items:append(IndexedItem.new(TextItem.new(spellSettings['job_names'], TextStyle.Default.TextSmall), IndexPath.new(1, 2)))
    items:append(IndexedItem.new(TextItem.new(spellSettings['job_abilities'], TextStyle.Default.TextSmall), IndexPath.new(1, 3)))
    items:append(IndexedItem.new(TextItem.new(spellSettings['conditions'], TextStyle.Default.TextSmall), IndexPath.new(1, 4)))

    self:getDataSource():addItems(items)

    backgroundView:setNeedsLayout()
    backgroundView:layoutIfNeeded()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SpellSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function SpellSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    if self:getNavigationBar() then
        --self:getNavigationBar():setTitle('Choose spells to buff yourself with.')
    end
end

function SpellSettingsEditor:setVisible(visible)
    if self:isVisible() == visible then
        return
    end
    CollectionView.setVisible(self, visible)

    --[[if self:isVisible() then
        self:updateActionsMenu()
    else
        if self.spellPicker then
            self.spellPicker:destroy()
        end
    end]]
end


return SpellSettingsEditor