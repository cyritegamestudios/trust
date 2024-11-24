local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local PartyMemberMenuItem = require('ui/settings/menus/party/PartyMemberMenuItem')
local PlayerMenuItem = require('ui/settings/menus/party/PlayerMenuItem')
local SoundTheme = require('cylibs/sounds/sound_theme')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local ValueRelay = require('cylibs/events/value_relay')
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

function PartyStatusWidget.new(frame, addonSettings, alliance, party, trust, mediaPlayer, soundTheme)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(14)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(Widget.new(frame, "Party", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4), 20), PartyStatusWidget)

    self.alliance = alliance

    self.party = ValueRelay.new(party)


    self.party_index = ValueRelay.new(-1)
    self.party_member_names = L{}
    self.partyDisposeBag = DisposeBag.new()

    local assistTargetItem = ImageItem.new(windower.addon_path..'assets/icons/icon_assist_target.png', 6, 6)
    self.assistTargetIcon = ImageCollectionViewCell.new(assistTargetItem)

    local leftArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_left.png', 14, 7)
    self.leftArrowButton = ImageCollectionViewCell.new(leftArrowButtonItem)

    local rightArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_right.png', 14, 7)
    self.rightArrowButton = ImageCollectionViewCell.new(rightArrowButtonItem)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local party_member = self.party:get_party_member_named(item:getText())
            if party_member then
                if party_member:get_name() == windower.ffxi.get_player().name then
                    local playerMenuItem = PlayerMenuItem.new(party_member, self.party, addonSettings:getSettings().remote_commands.whitelist, trust)
                    coroutine.schedule(function()
                        self:resignFocus()
                        hud:closeAllMenus()
                        hud:openMenu(playerMenuItem)
                    end, 0.2)
                elseif party_member:is_trust() then
                    party:set_assist_target(party_member)
                else
                    local partyMemberMenuItem = PartyMemberMenuItem.new(party_member, self.party, addonSettings:getSettings().remote_commands.whitelist, trust)
                    coroutine.schedule(function()
                        self:resignFocus()
                        hud:closeAllMenus()
                        hud:openMenu(partyMemberMenuItem)
                    end, 0.2)
                end
            else
                mediaPlayer:playSound(soundTheme:getSoundForAction(SoundTheme.UI.Menu.Error))
                addon_system_error(item:getText()..' is out of range.')
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(alliance:on_alliance_updated():addAction(function(_)
        self:updateButtons()
        self:set_party_member_names(self.party:get_party_members(self.party_index:getValue() == 1):map(function(p) return p:get_name() end))
    end), alliance:on_alliance_updated())

    self:getDisposeBag():add(self.party_index:onValueChanged():addAction(function(_, party_index)
        self:set_party(self.alliance:get_parties()[party_index])

        local is_primary_party = self.party_index:getValue() == 1
        if is_primary_party then
            self:setTitle("Party", 20)
        else
            self:setTitle("Alliance", 40)
        end
    end), self.party_index:onValueChanged())


    self:getDisposeBag():add(party:on_party_assist_target_change():addAction(function(_, party_member)
        self:setAssistTarget(party_member)
    end), party:on_party_assist_target_change())

    self.party_index:setValue(1)

    return self
end

function PartyStatusWidget:set_party(party)
    self.party = party

    local is_primary_party = self.party_index:getValue() == 1

    if is_primary_party then
        self:setAssistTarget(self.party:get_assist_target())
    else
        self:setAssistTarget(nil)
    end

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

    self.partyDisposeBag:dispose()
    self.partyDisposeBag:add(self.party:on_party_member_added():addAction(function(party_member)
        if is_primary_party then
            self.partyDisposeBag:add(party_member:on_position_change():addAction(function(p, x, y, z)
                on_position_change(p, x, y, z)
            end), party_member:on_position_change())
        end
        self:set_party_member_names(self.party:get_party_members(is_primary_party):map(function(p) return p:get_name() end))
    end), self.party:on_party_member_added())

    self.partyDisposeBag:add(self.party:on_party_member_added():addAction(function(party_member)
        self:set_party_member_names(self.party:get_party_members(is_primary_party):map(function(p) return p:get_name() end))
    end), self.party:on_party_member_added())

    self:updateButtons()

    self:set_party_member_names(self.party:get_party_members(is_primary_party):map(function(p) return p:get_name() end))
end

function PartyStatusWidget:set_party_member_names(party_member_names)
    if self.party_member_names == party_member_names
            or party_member_names:filter(function(p) return p:empty() end):length() > 0 then
        return
    end
    self.party_member_names = party_member_names

    if self.party_member_names:length() == 0 and self.party_index ~= 1 then
        self.party_index:setValue(1)
        return
    end

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

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
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
    if party_member then
        local indexPath = self:indexPathForPartyMember(party_member)
        if indexPath then
            local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
            if cell then
                self:getContentView():addSubview(self.assistTargetIcon)
                self.assistTargetIcon:setVisible(true)
                self.assistTargetIcon:setPosition(cell:getPosition().x - 3, cell:getPosition().y + cell:getSize().height - 6)
                self.assistTargetIcon:layoutIfNeeded()
            end
        end
    else
        self.assistTargetIcon:setVisible(false)
        self.assistTargetIcon:removeFromSuperview()
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
    return nil
end

function PartyStatusWidget:updateButtons()
    local num_valid_parties = self:get_num_valid_parties()
    for button in L{ self.leftArrowButton, self.rightArrowButton }:it() do
        if num_valid_parties > 1 then
            self:getContentView():addSubview(button)
        else
            button:setVisible(false)
            button:removeFromSuperview()
        end
    end
end

function PartyStatusWidget:setPosition(x, y)
    Widget.setPosition(self, x, y)

    self.leftArrowButton:setPosition(-14, 3)
    self.rightArrowButton:setPosition(self:getSize().width, 3)
end

function PartyStatusWidget:hitTest(x, y)
    local success = Widget.hitTest(self, x, y)
    if success then
        return success
    end
    if self.leftArrowButton:hitTest(x, y) then
        return true
    end
    if self.rightArrowButton:hitTest(x, y) then
        return true
    end
    return false
end

function PartyStatusWidget:onMouseEvent(type, x, y, delta)
    if type == Mouse.Event.Click or type == Mouse.Event.ClickRelease then
        if self.leftArrowButton:hitTest(x, y) then
            if type == Mouse.Event.ClickRelease then
                local party_index = self.party_index:getValue() - 1
                if party_index <= 0 then
                    party_index = self:get_num_valid_parties()
                end
                self.party_index:setValue(party_index)
            end
            return true
        end
        if self.rightArrowButton:hitTest(x, y) then
            if type == Mouse.Event.ClickRelease then
                local party_index = self.party_index:getValue() + 1
                if party_index > self:get_num_valid_parties() then
                    party_index = 1
                end
                self.party_index:setValue(party_index)
            end
            return true
        end
    end
    return Widget.onMouseEvent(self, type, x, y, delta)
end

function PartyStatusWidget:get_num_valid_parties()
    return self.alliance:get_parties():filter(function(p)
        return p:get_party_members(true):length() > 0
    end):length()
end

return PartyStatusWidget