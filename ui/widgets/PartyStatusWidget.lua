local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local PartyStatusWidget = setmetatable({}, {__index = CollectionView })
PartyStatusWidget.__index = PartyStatusWidget

PartyStatusWidget.TextSmall = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.white,
        true
)

function PartyStatusWidget.new(frame, addonSettings, party)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(14)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4)), PartyStatusWidget)

    self.addonSettings = addonSettings
    self.party = party
    self.events = {}

    self:setScrollEnabled(false)
    self:setUserInteractionEnabled(true)

    local backgroundView = FFXIBackgroundView.new(frame)
    self:setBackgroundImageView(backgroundView)

    backgroundView:setTitle("Party")

    local assistTargetItem = ImageItem.new(windower.addon_path..'assets/icons/icon_assist_target.png', 6, 6)
    self.assistTargetIcon = ImageCollectionViewCell.new(assistTargetItem)

    self:getContentView():addSubview(self.assistTargetIcon)

    self:setPartyMembers(party:get_party_members(true))

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(Mouse.input():onMouseEvent():addAction(function(type, x, y, delta, blocked)
        if type == Mouse.Event.Click then
            if self:hitTest(x, y) then
                local startPosition = self:getAbsolutePosition()
                self.dragging = { x = startPosition.x, y = startPosition.y, dragX = x, dragY = y }
                Mouse.input().blockEvent = true
            end
        elseif type == Mouse.Event.Move then
            if self.dragging then
                Mouse.input().blockEvent = true

                local newX = self.dragging.x + (x - self.dragging.dragX)
                local newY = self.dragging.y + (y - self.dragging.dragY)

                self:setPosition(newX, newY)
                self:layoutIfNeeded()
            end
            return true
        elseif type == Mouse.Event.ClickRelease then
            if self.dragging then
                self.dragging = nil
                Mouse.input().blockEvent = true
                coroutine.schedule(function()
                    Mouse.input().blockEvent = false
                end, 0.1)
            end
        else
            self.dragging = nil
            Mouse.input().blockEvent = false
        end
        return false
    end), Mouse.input():onMouseEvent())

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local party_member = party:get_party_member_named(item:getText())
            if party_member then
                party:set_assist_target(party_member)
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(party:on_party_member_added():addAction(function(partyMember)
        self:addPartyMember(partyMember)
    end), party:on_party_member_added())

    self:getDisposeBag():add(party:on_party_member_removed():addAction(function(party_member)
        self:removePartyMember(party_member)
    end), party:on_party_member_removed())

    self:getDisposeBag():add(party:on_party_assist_target_change():addAction(function(_, party_member)
        self:setAssistTarget(party_member)
    end), party:on_party_assist_target_change())

    self.events.tic = windower.register_event('time change', function() self:tic()  end)

    return self
end

function PartyStatusWidget:destroy()
    CollectionView.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function PartyStatusWidget:tic()
    for partyMember in self.party:get_party_members():it() do
        local indexPath = self:indexPathForPartyMember(partyMember)
        if indexPath then
            local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
            if cell then
                local dist = ffxi_util.distance(ffxi_util.get_player_position(), partyMember:get_position())
                if dist > 21 then
                    cell:setAlpha(150)
                else
                    cell:setAlpha(255)
                end
                cell:setUserInteractionEnabled(dist <= 21)
            end
        end
    end
end

function PartyStatusWidget:indexPathForPartyMember(party_member)
    for i = 1, self:getDataSource():numberOfItemsInSection(1) do
        local indexPath = IndexPath.new(1, i)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item and item:getText() == party_member:get_name() then
            return indexPath
        end
    end
end

function PartyStatusWidget:setAssistTarget(party_member)
    local indexPath = self:indexPathForPartyMember(party_member)
    if indexPath then
        local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
        if cell then
            self.assistTargetIcon:setPosition(cell:getPosition().x - 3, cell:getPosition().y + cell:getSize().height - 6)
            self.assistTargetIcon:layoutIfNeeded()
        end
    end
end

function PartyStatusWidget:setPartyMembers(partyMember)
    self:getDataSource():removeAllItems()

    local rowIndex = 0

    local itemsToUpdate = partyMember:map(function(p)
        local style = PartyStatusWidget.TextSmall
        return TextItem.new(p:get_name(), style)
    end):map(function(item)
        rowIndex = rowIndex + 1
        return IndexedItem.new(item, IndexPath.new(1, rowIndex))
    end)

    self:getDataSource():updateItems(itemsToUpdate)

    self:setAssistTarget(self.party:get_assist_target())

    self:setSize(self:getSize().width, self:getContentSize().height)
    self:layoutIfNeeded()
end

function PartyStatusWidget:addPartyMember(partyMember)
    self:setPartyMembers(self.party:get_party_members(true))
end

function PartyStatusWidget:removePartyMember(party_member)
    local indexPath = self:indexPathForPartyMember(party_member)
    if indexPath then
        self:getDataSource():removeItem(indexPath)
        self:setSize(self:getSize().width, self:getContentSize().height)
        self:layoutIfNeeded()
    end
end

function PartyStatusWidget:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return
    end

    self.backgroundImageView:setSize(self.frame.width, self:getContentSize().height)
    self.backgroundImageView:layoutIfNeeded()
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate to set.
-- @tparam number y The y-coordinate to set.
--
function PartyStatusWidget:setPosition(x, y)
    if self.frame.x == x and self.frame.y == y then
        return
    end
    CollectionView.setPosition(self, x, y)

    self.addonSettings:getSettings().hud.party.position.x = x
    self.addonSettings:getSettings().hud.party.position.y = y
    self.addonSettings:saveSettings(true)
end

return PartyStatusWidget