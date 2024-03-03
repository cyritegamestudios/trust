local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
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
local zone_util = require('cylibs/util/zone_util')

local PartyMemberView = setmetatable({}, {__index = CollectionView })
PartyMemberView.__index = PartyMemberView

---
-- Creates a new PartyMemberView.
--
-- @tparam Party party The party data.
-- @tparam list trusts The list of alter egos.
-- @treturn PartyMemberView The newly created PartyMemberView instance.
--
function PartyMemberView.new(party, player, actionQueue, trusts)
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

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0), 10), nil, CollectionViewStyle.empty()), PartyMemberView)

    self.trusts = trusts
    self.buffViews = {}

    self:getDisposeBag():add(party:on_party_member_added():addAction(function(partyMember)
        self:addPartyMember(party, partyMember)
        self:updatePartyMembers(party)
    end), party:on_party_member_added())

    self:getDisposeBag():add(party:on_party_member_removed():addAction(function(party_member)
        self:updatePartyMembers(party)
    end), party:on_party_member_removed())

    local itemsToAdd = L{}

    -- Create placeholder cells
    local partyMembers = party:get_party_members(true)
    for partyMemberIndex = 1, 6 do
        itemsToAdd:append(IndexedItem.new(TextItem.new("Empty", TextStyle.Default.HeaderSmall), IndexPath.new(partyMemberIndex, 1)))

        local buffsView = self:createBuffsView()
        table.insert(self.buffViews, partyMemberIndex, buffsView)

        itemsToAdd:append(IndexedItem.new(ViewItem.new(buffsView), IndexPath.new(partyMemberIndex, 2)))

        self:getDisposeBag():addAny(L{ buffsView })

        local partyMember = partyMembers[partyMemberIndex]
        if partyMember then
            self:addPartyMember(party, partyMember)
        end
    end

    self:getDataSource():addItems(itemsToAdd)
    self:setScrollEnabled(false)

    self:updatePartyMembers(party)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local partyMembers = party:get_party_members(true)
        local partyMember = partyMembers[indexPath.section]
        if partyMember then
            windower.send_command('trust assist '..partyMember:get_name())
        else
            self:callAlterEgo(party, player, actionQueue)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PartyMemberView:addPartyMember(party, partyMember)
    self:getDisposeBag():add(partyMember:on_gain_buff():addAction(function(p, buffId)
        self:updatePartyMembers(party, function(otherPartyMember) return otherPartyMember:get_name() == p:get_name()  end)
    end), partyMember:on_gain_buff())

    self:getDisposeBag():add(partyMember:on_lose_buff():addAction(function(p, buffId)
        self:updatePartyMembers(party, function(otherPartyMember) return otherPartyMember:get_name() == p:get_name()  end)
    end), partyMember:on_lose_buff())
end

function PartyMemberView:updateBuffs(partyMember, buffsView)
    local allBuffIds = partyMember and partyMember:get_buff_ids():sort() or L{}

    local buffItems = L{}

    local buffIndex = 1
    for buffId in allBuffIds:it() do
        if buffIndex <= 15 then
            buffItems:append(IndexedItem.new(ImageItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20), IndexPath.new(1, buffIndex)))
            buffIndex = buffIndex + 1
        end
    end
    for i = buffIndex, 15 do
        buffItems:append(IndexedItem.new(ImageItem.new('', 20, 20), IndexPath.new(1, buffIndex)))
    end

    buffsView:getDataSource():updateItems(buffItems)
end

function PartyMemberView:createBuffsView()
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)
    local collectionView = CollectionView.new(dataSource, HorizontalFlowLayout.new(2, Padding.equal(0)), nil, CollectionViewStyle.empty())
    collectionView:setScrollEnabled(false)

    local buffItems = L{}
    for buffIndex = 1, 15 do
        buffItems:append(IndexedItem.new(ImageItem.new('', 20, 20), IndexPath.new(1, buffIndex)))
    end

    dataSource:addItems(buffItems)

    return collectionView
end

function PartyMemberView:updatePartyMembers(party, partyMemberFilter)
    partyMemberFilter = partyMemberFilter or function(_) return true  end

    local itemsToUpdate = L{}

    local partyMembers = party:get_party_members(true)
    logger.notice("party_member_view", "found", partyMembers)
    for partyMemberIndex = 1, 6 do
        local partyMember = partyMembers[partyMemberIndex]
        if partyMember then
            if partyMemberFilter(partyMember) then
                local name = partyMember:get_name()
                if partyMember:get_zone_id() ~= windower.ffxi.get_info().zone then
                    name = name..' ('..res.zones[partyMember:get_zone_id()].name..')'
                end
                itemsToUpdate:append(IndexedItem.new(TextItem.new(name, TextStyle.Default.HeaderSmall), IndexPath.new(partyMemberIndex, 1)))

                local buffsView = self.buffViews[partyMemberIndex]
                self:updateBuffs(partyMember, buffsView)

                buffsView:setNeedsLayout()
                buffsView:layoutIfNeeded()
            end
        else
            local buffsView = self.buffViews[partyMemberIndex]
            self:updateBuffs(nil, buffsView)

            itemsToUpdate:append(IndexedItem.new(TextItem.new("Empty", TextStyle.Default.HeaderSmall), IndexPath.new(partyMemberIndex, 1)))
        end
    end

    self:getDataSource():updateItems(itemsToUpdate)
end

function PartyMemberView:callAlterEgo(party, player, actionQueue)
    local info = windower.ffxi.get_info()
    if zone_util.is_city(info.zone) then
        return
    end
    for trust in self.trusts:it() do
        local sanitizedName = trust
        if trusts:with('enl', trust) then
            sanitizedName = trusts:with('enl', trust).en
        end
        if party:get_party_member_named(sanitizedName) == nil then
            local spell = res.spells:with('en', trust)
            if spell then
                local callAction = SpellAction.new(0, 0, 0, spell.id, nil, player)
                callAction.priority = ActionPriority.highest

                actionQueue:push_action(callAction, true)
            end
            return
        end
    end
end

function PartyMemberView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("View buffs and debuffs on the party.")
end

return PartyMemberView