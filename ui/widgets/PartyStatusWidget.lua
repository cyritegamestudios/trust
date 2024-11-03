local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Padding = require('cylibs/ui/style/padding')
local PartyMemberMenuItem = require('ui/settings/menus/party/PartyMemberMenuItem')
local PlayerMenuItem = require('ui/settings/menus/party/PlayerMenuItem')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local PartyStatusWidget = setmetatable({}, {__index = Widget })
PartyStatusWidget.__index = PartyStatusWidget
PartyStatusWidget.__type = "PartyStatusWidget"


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

function PartyStatusWidget.new(frame, addonSettings, party, trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(14)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(Widget.new(frame, "Party", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4), 20), PartyStatusWidget)

    self.party = party

    local assistTargetItem = ImageItem.new(windower.addon_path..'assets/icons/icon_assist_target.png', 6, 6)
    self.assistTargetIcon = ImageCollectionViewCell.new(assistTargetItem)

    self:getContentView():addSubview(self.assistTargetIcon)

    self:setPartyMembers(party:get_party_members(true))

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local party_member = party:get_party_member_named(item:getText())
            if party_member then
                if party_member:get_name() == windower.ffxi.get_player().name then
                    local playerMenuItem = PlayerMenuItem.new(party_member, party, addonSettings:getSettings().remote_commands.whitelist, trust)
                    coroutine.schedule(function()
                        self:resignFocus()
                        hud:closeAllMenus()
                        hud:openMenu(playerMenuItem)
                    end, 0.2)
                elseif party_member:is_trust() then
                    party:set_assist_target(party_member)
                else
                    local partyMemberMenuItem = PartyMemberMenuItem.new(party_member, party, addonSettings:getSettings().remote_commands.whitelist, trust)
                    coroutine.schedule(function()
                        self:resignFocus()
                        hud:closeAllMenus()
                        hud:openMenu(partyMemberMenuItem)
                    end, 0.2)
                end
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

    return self
end

-- FIXME: re-add this
function PartyStatusWidget:tic(old_time, new_time)
    Widget.tic(self, old_time, new_time)

    local player = self.party:get_player()
    for partyMember in self.party:get_party_members():it() do
        local indexPath = self:indexPathForPartyMember(partyMember)
        if indexPath then
            local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
            if cell then
                local dist = ffxi_util.distance(player:get_position(), partyMember:get_position())
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

function PartyStatusWidget:getSettings(addonSettings)
    return addonSettings:getSettings().party_widget
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

        self:setAssistTarget(self.party:get_assist_target())
    end
end

function PartyStatusWidget:setExpanded(expanded)
    if not Widget.setExpanded(self, expanded) then
        return false
    end

    if expanded then
        self.assistTargetIcon:setVisible(true)
        self:getContentView():addSubview(self.assistTargetIcon)
        self:setPartyMembers(self.party:get_party_members(true))
    else
        self.assistTargetIcon:removeFromSuperview()
        self.assistTargetIcon:setVisible(false)
        self:getDataSource():removeAllItems()
        self:layoutIfNeeded()
    end
    self.assistTargetIcon:layoutIfNeeded()
end

return PartyStatusWidget