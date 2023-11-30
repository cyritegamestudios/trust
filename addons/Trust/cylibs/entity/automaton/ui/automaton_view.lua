local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SpellAction = require('cylibs/actions/spell')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local trusts = require('cylibs/res/trusts')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewItem = require('cylibs/ui/collection_view/items/view_item')

local AutomatonView = setmetatable({}, {__index = CollectionView })
AutomatonView.__index = AutomatonView

function AutomatonView.new(trustSettings, settingsMode)
    local dataSource = CollectionViewDataSource.new(function(item)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(20)
            cell:setUserInteractionEnabled(true)
            return cell
        elseif item.__type == ViewItem.__type then
            local cell = ContainerCollectionViewCell.new(item)
            cell:setItemSize(20)
            return cell
        end
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0), 10)), AutomatonView)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.defaultManeuvers = T(self.trustSettings:getSettings())[self.settingsMode.value].DefaultManeuvers
    self.overdriveManeuvers = T(self.trustSettings:getSettings())[self.settingsMode.value].OverdriveManeuvers
    self.maneuverSet = self.defaultManeuvers[state.ManeuverMode.value]
    self.buffsView = self:createBuffsView()

    state.ManeuverMode:on_state_change():addAction(function(_, new_value)
        if self.defaultManeuvers[new_value] then
            self.maneuverSet = self.defaultManeuvers[new_value]
            self:updateManeuvers()
        end
    end)

    local itemsToAdd = L{}

    itemsToAdd:append(IndexedItem.new(TextItem.new("Maneuvers", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    itemsToAdd:append(IndexedItem.new(ViewItem.new(self.buffsView), IndexPath.new(1, 2)))

    self:getDisposeBag():addAny(L{ self.buffsView })

    self:getDataSource():addItems(itemsToAdd)
    self:setScrollEnabled(false)

    self:updateManeuvers()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function AutomatonView:updateManeuvers()
    local allManeuverIds = L{}
    for maneuver in self.maneuverSet:it() do
        for i = 1, maneuver.Amount do
            allManeuverIds:append(res.buffs:with('name', maneuver.Name).id)
        end
    end

    local buffItems = L{}

    local buffIndex = 1
    for buffId in allManeuverIds:it() do
        if buffIndex <= 3 then
            buffItems:append(IndexedItem.new(ImageItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20), IndexPath.new(1, buffIndex)))
            buffIndex = buffIndex + 1
        end
    end

    self.buffsView:getDataSource():updateItems(buffItems)
end

function AutomatonView:createBuffsView()
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)
    local collectionView = CollectionView.new(dataSource, HorizontalFlowLayout.new(2, Padding.equal(0)))
    collectionView:setScrollEnabled(false)

    local buffItems = L{}
    for buffIndex = 1, 3 do
        buffItems:append(IndexedItem.new(ImageItem.new('', 20, 20), IndexPath.new(1, buffIndex)))
    end

    dataSource:addItems(buffItems)

    return collectionView
end

function AutomatonView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("See automaton status.")
end

return AutomatonView