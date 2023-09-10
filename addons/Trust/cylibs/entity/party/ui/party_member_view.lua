local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewItem = require('cylibs/ui/collection_view/items/view_item')

local PartyMemberView = setmetatable({}, {__index = CollectionView })
PartyMemberView.__index = PartyMemberView

---
-- Creates a new PartyMemberView.
--
-- @tparam table party The party data.
-- @tparam Layout layout The layout for the view.
-- @treturn PartyMemberView The newly created PartyMemberView instance.
--
function PartyMemberView.new(party)
    local dataSource = CollectionViewDataSource.new(function(item)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(20)
            return cell
        elseif item.__type == ViewItem.__type then
            local cell = ContainerCollectionViewCell.new(item)
            cell:setItemSize(20)
            return cell
        end
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0), 10)), PartyMemberView)

    self.buffViews = {}

    self:getDisposeBag():add(party:on_party_member_added():addAction(function(partyMember)
        self:addPartyMember(party, partyMember)
    end), party:on_party_member_added())

    self:getDisposeBag():add(party:on_party_member_removed():addAction(function(party_member)
        self:updatePartyMembers(party)
    end), party:on_party_member_removed())

    local partyMembers = party:get_party_members(true)
    for partyMemberIndex = 1, 6 do
        self:getDataSource():addItem(TextItem.new("Empty", TextStyle.Default.Text), IndexPath.new(partyMemberIndex, 1))

        local buffsView = self:createBuffsView()
        table.insert(self.buffViews, partyMemberIndex, buffsView)

        self:getDataSource():addItem(ViewItem.new(buffsView), IndexPath.new(partyMemberIndex, 2))

        self:getDisposeBag():addAny(L{ buffsView })

        local partyMember = partyMembers[partyMemberIndex]
        if partyMember then
            self:addPartyMember(party, partyMember)
        end
    end

    self:updatePartyMembers(party)

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
    local allBuffIds = partyMember:get_buff_ids():sort()

    local buffIndex = 1
    for buffId in allBuffIds:it() do
        if buffIndex <= 15 then
            buffsView:getDataSource():updateItem(ImageItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20), IndexPath.new(1, buffIndex))
            buffIndex = buffIndex + 1
        end
    end
    for i = buffIndex, 15 do
        buffsView:getDataSource():updateItem(ImageItem.new('', 20, 20), IndexPath.new(1, buffIndex))
    end
end

function PartyMemberView:updatePartyMembers(party, partyMemberFilter)
    partyMemberFilter = partyMemberFilter or function(_) return true  end

    local partyMembers = party:get_party_members(true)
    for partyMemberIndex = 1, 6 do
        local partyMember = partyMembers[partyMemberIndex]
        if partyMember then
            if partyMemberFilter(partyMember) then
                self:getDataSource():updateItem(TextItem.new(partyMembers[partyMemberIndex]:get_name(), TextStyle.Default.Text), IndexPath.new(partyMemberIndex, 1))

                local buffsView = self.buffViews[partyMemberIndex]
                self:updateBuffs(partyMember, buffsView)

                buffsView:setNeedsLayout()
                buffsView:layoutIfNeeded()
            end
        else
            self:getDataSource():updateItem(TextItem.new("Empty", TextStyle.Default.Text), IndexPath.new(partyMemberIndex, 1))
        end
    end
end

function PartyMemberView:createBuffsView()
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)
    local collectionView = CollectionView.new(dataSource, HorizontalFlowLayout.new(2, Padding.equal(0)))

    for buffIndex = 1, 15 do
        dataSource:addItem(ImageItem.new('', 20, 20), IndexPath.new(1, buffIndex))
    end

    return collectionView
end

return PartyMemberView