local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
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
    self.party_member_names = L{}
    self.partyDisposeBag = DisposeBag.new()

    local assistTargetItem = ImageItem.new(windower.addon_path..'assets/icons/icon_assist_target.png', 6, 6)
    self.assistTargetIcon = ImageCollectionViewCell.new(assistTargetItem)

    self:getContentView():addSubview(self.assistTargetIcon)

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
            else
                addon_system_error(item:getText()..' is out of range.')
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(WindowerEvents.AllianceMemberListUpdate:addAction(function(a)
        coroutine.schedule(function()
            self:set_party_member_names(party_util.get_party_member_names(false))
        end, 0.1)
    end), WindowerEvents.AllianceMemberListUpdate)

    local on_position_change = function(p, x, y, z)
        if S(self.party_member_names):contains(p:get_name()) then
            if p:get_id() == windower.ffxi.get_player().id then
                for party_member in self.party:get_party_members(false):it() do
                    self:updatePartyMember(party_member)
                end
            else
                self:updatePartyMember(p)
            end
        end
    end

    self:getDisposeBag():add(party:on_party_member_added():addAction(function(party_member)
        self.partyDisposeBag:add(party_member:on_position_change():addAction(function(p, x, y, z)
            on_position_change(p, x, y, z)
        end), party_member:on_position_change())
    end), party:on_party_member_added())

    self:getDisposeBag():add(party:on_party_assist_target_change():addAction(function(_, party_member)
        self:setAssistTarget(party_member)
    end), party:on_party_assist_target_change())

    self:set_party_member_names(party_util.get_party_member_names(false))

    for party_member in self.party:get_party_members(true):it() do
        self.partyDisposeBag:add(party_member:on_position_change():addAction(function(p, x, y, z)
            on_position_change(p, x, y, z)
        end), party_member:on_position_change())
    end

    return self
end

function PartyStatusWidget:set_party_member_names(party_member_names)
    if self.party_member_names == party_member_names
            or party_member_names:filter(function(p) return p:empty() end):length() > 0 then
        return
    end
    self.party_member_names = party_member_names

    self:getDataSource():removeAllItems()

    local itemsToAdd = IndexedItem.fromItems(L(self.party_member_names:map(function(party_member_name)
        local item = TextItem.new(party_member_name, PartyStatusWidget.TextSmall)
        item:setEnabled(self:is_enabled(party_member_name))
        return item
    end)), 1)

    self:getDataSource():addItems(itemsToAdd)

    self:setAssistTarget(self.party:get_assist_target())

    self:setSize(self:getSize().width, self:getContentSize().height)
    self:layoutIfNeeded()
end

function PartyStatusWidget:is_enabled(party_member_name)
    local party_member = self.party:get_party_member_named(party_member_name)
    if party_member then
        if not party_member:is_trust() and party_member:get_id() ~= windower.ffxi.get_player().id then
            if not party_member:get_mob() or party_member:get_mob().distance:sqrt() > 21 or party_member:get_zone_id() ~= windower.ffxi.get_info().zone then
                return false
            end
        end
    else
        return false
    end
    return true
end

function PartyStatusWidget:getSettings(addonSettings)
    return addonSettings:getSettings().party_widget
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

function PartyStatusWidget:updatePartyMember(partyMember)
    local indexPath = self:indexPathForPartyMember(partyMember)
    if indexPath then
        local item = TextItem.new(partyMember:get_name(), PartyStatusWidget.TextSmall)
        item:setEnabled(self:is_enabled(partyMember:get_name()))

        self:getDataSource():updateItem(item, indexPath)

        self:setNeedsLayout()
        self:layoutIfNeeded()
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

function PartyStatusWidget:setExpanded(expanded)
    if not Widget.setExpanded(self, expanded) then
        return false
    end
end

return PartyStatusWidget