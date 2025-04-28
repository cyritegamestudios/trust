local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local Frame = require('cylibs/ui/views/frame')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local PartyMemberMenuItem = require('ui/settings/menus/party/PartyMemberMenuItem')
local PlayerMenuItem = require('ui/settings/menus/party/PlayerMenuItem')
local SoundTheme = require('cylibs/sounds/sound_theme')
local TargetLock = require('cylibs/entity/party/target_lock')
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

function PartyStatusWidget.new(frame, alliance, party, trust, mediaPlayer, soundTheme)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        else
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Party", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4), 20), PartyStatusWidget)

    self.alliance = alliance

    self.parties = self:get_parties()
    self.num_parties = ValueRelay.new(self:get_num_valid_parties())
    self.party_index = ValueRelay.new(-1)
    self.partyDisposeBag = DisposeBag.new()

    local leftArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_left.png', 14, 7)
    self.leftArrowButton = ImageCollectionViewCell.new(leftArrowButtonItem)

    local rightArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_right.png', 14, 7)
    self.rightArrowButton = ImageCollectionViewCell.new(rightArrowButtonItem)

    local buffsDataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(16)
        return cell
    end)
    self.buffsList = CollectionView.new(buffsDataSource, HorizontalFlowLayout.new(0, Padding.equal(0)), nil, CollectionViewStyle.empty())
    self.buffsList:setScrollEnabled(false)
    self.buffsList:setSize(100, 16)
    self.buffsList:setVisible(false)

    self:getContentView():addSubview(self.buffsList)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectAllItems()
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local party_member = self.alliance:get_alliance_member_named(item:getText())
            if party_member then
                if party_member:get_name() == windower.ffxi.get_player().name then
                    local playerMenuItem = PlayerMenuItem.new(party_member, party, alliance, trust)
                    coroutine.schedule(function()
                        self:resignFocus()
                        hud:closeAllMenus()
                        hud:openMenu(playerMenuItem)
                    end, 0.2)
                elseif party_member:is_trust() then
                    party:set_assist_target(party_member)
                else
                    local partyMemberMenuItem = PartyMemberMenuItem.new(party_member, party, trust)
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

    self:getDisposeBag():add(self:getDelegate():didHighlightItemAtIndexPath():addAction(function(indexPath)
        self.buffsList:getDataSource():removeAllItems()

        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local party_member = self.alliance:get_alliance_member_named(item:getText())
            if party_member and not party_member:is_trust() then
                local allBuffIds = party_member:get_buff_ids():sort() or L{}

                local buffItems = L{}

                local buffIndex = 1
                for buffId in allBuffIds:it() do
                    if buffIndex > 8 then
                        break
                    end
                    buffItems:append(IndexedItem.new(ImageItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 16, 16), IndexPath.new(1, buffIndex)))
                    buffIndex = buffIndex + 1
                end

                self.buffsList:getDataSource():addItems(buffItems)

                self.buffsList:setPosition(0, self:getSize().height + 4)
                --self.buffsList:setPosition((buffIndex - 1) * -16 - 4, 20 * (indexPath.row - 1))
                self.buffsList:setVisible(true)
            else
                self.buffsList:setVisible(false)
            end
            self.buffsList:setNeedsLayout()
            self.buffsList:layoutIfNeeded()
        end
    end), self:getDelegate():didHighlightItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDehighlightItemAtIndexPath():addAction(function(indexPath)
        self.buffsList:getDataSource():removeAllItems()
        self.buffsList:setVisible(false)
        self.buffsList:layoutIfNeeded()
    end), self:getDelegate():didDehighlightItemAtIndexPath())

    self:getDisposeBag():add(WindowerEvents.AllianceMemberListUpdate:addAction(function(_)
        self.parties = self:get_parties()

        local num_parties = self:get_num_valid_parties()
        if num_parties == 1 then
            self.party_index:setValue(1)
        else
            self:set_party(self.parties[self.party_index:getValue()])
        end
        self.num_parties:setValue(num_parties)
    end), WindowerEvents.AllianceMemberListUpdate)

    self:getDisposeBag():add(self.party_index:onValueChanged():addAction(function(_, party_index)
        self:set_party(self.parties[party_index])
    end), self.party_index:onValueChanged())

    self:getDisposeBag():add(self.num_parties:onValueChanged():addAction(function(_, num_parties)
        self:updateButtons()
    end), self.num_parties:onValueChanged())

    self:getDisposeBag():add(party:on_party_assist_target_change():addAction(function(_, party_member)
        self:set_party(self.parties[self.party_index:getValue()], true)
    end), party:on_party_assist_target_change())

    self.party_index:setValue(1)

    self:updateButtons()

    return self
end

-------
-- Returns a list of parties.
-- @treturn list MobMetada List of list of party member info for each party in the alliance.
function PartyStatusWidget:get_parties()
    local parties = L{
        L{},
        L{},
        L{},
    }
    for key, party_member_info in pairs(windower.ffxi.get_party()) do
        if type(party_member_info) == 'table' then
            if string.match(key, "p[0-5]") then
                parties[1]:append(party_member_info)
            elseif string.match(key, "a[10-15]") then
                parties[2]:append(party_member_info)
            elseif string.match(key, "a[20-25]") then
                parties[3]:append(party_member_info)
            end
        end
    end
    return parties
end

function PartyStatusWidget:get_assist_target()
    local assist_target = self.alliance:get_party(windower.ffxi.get_player().name):get_assist_target()
    if assist_target.__type == TargetLock.__type then
        assist_target = self.alliance:get_alliance_member_named(windower.ffxi.get_player().name)
    end
    return assist_target
end

-------
-- Sets the party to be displayed in the widget.
-- @tparam list party List of party member info
-- @tparam boolean force_update Forces the party widget to update
function PartyStatusWidget:set_party(party, force_update)
    if not force_update and (self.party and party:equals(self.party)) then
        return
    end
    self.party = party

    local is_primary_party = self.party_index:getValue() == 1
    if is_primary_party then
        self:setTitle("Party", 20)
    else
        self:setTitle("Alliance", 40)
    end

    self:getDataSource():removeAllItems()

    local assist_target = self:get_assist_target()

    local itemsToAdd = IndexedItem.fromItems(L(self.party:map(function(party_member_info)
        local item = TextItem.new(party_member_info.name, PartyStatusWidget.TextSmall)
        --item:setEnabled(self:is_enabled(party_member_info.name))
        if party_member_info.name == assist_target.name then
            item = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/icons/icon_assist_target.png', 6, 6), item, 0, Frame.new(-4, 8))
        end
        return item
    end)), 1)

    self:getDataSource():addItems(itemsToAdd)

    self:setSize(self:getSize().width, self:getContentSize().height)
    self:setVisible(true)
    self:layoutIfNeeded()

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    --[[local on_position_change = function(p, x, y, z)
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
    end), self.party:on_party_member_added())]]
end

function PartyStatusWidget:is_enabled(party_member_name)
    local is_primary_party = self.party_index:getValue() == 1
    if not is_primary_party then
        return true
    end

    local party_member = self.alliance:get_alliance_member_named(party_member_name)
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

function PartyStatusWidget:updateButtons()
    local num_valid_parties = self:get_num_valid_parties()
    for button in L{ self.leftArrowButton, self.rightArrowButton }:it() do
        if num_valid_parties > 1 then
            self:getContentView():addSubview(button)

            button:setVisible(true)
            button:layoutIfNeeded()
        else
            button:setVisible(false)
            button:removeFromSuperview()
        end
    end
    self:getContentView():setNeedsLayout()
    self:getContentView():layoutIfNeeded()
end

function PartyStatusWidget:get_num_valid_parties()
    return self.parties:filter(function(party)
        return party:length() > 0
    end):length()
end

function PartyStatusWidget:setPosition(x, y)
    Widget.setPosition(self, x, y)

    self.leftArrowButton:setPosition(-14, 3)
    self.rightArrowButton:setPosition(self:getSize().width, 3)
end

function PartyStatusWidget:getMaxHeight()
    return 94
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

function PartyStatusWidget:setHasFocus(hasFocus)
    Widget.setHasFocus(self, hasFocus)
    if not self:hasFocus() then
        self:getDelegate():deHighlightAllItems()
    end
end

return PartyStatusWidget