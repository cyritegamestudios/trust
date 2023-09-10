local PartyMemberListItem = require('cylibs/entity/party/ui/party_member_list_item')

local ListItemDataProvider = require('cylibs/ui/lists/list_item_data_provider')

local PartyMemberDataProvider = setmetatable({}, {__index = ListItemDataProvider })
PartyMemberDataProvider.__index = PartyMemberDataProvider

-- Creates a new PartyMemberDataProvider instance.
--
-- @tparam Party party The party data.
-- @treturn PartyMemberDataProvider The newly created PartyMemberDataProvider instance.
function PartyMemberDataProvider.new(party)
    local self = setmetatable(ListItemDataProvider.new(), PartyMemberDataProvider)

    self.party = party

    self:getDisposeBag():add(party:on_party_member_added():addAction(function(party_member)
        self:addPartyMember(party_member)
    end), party:on_party_member_added())

    self:getDisposeBag():add(party:on_party_member_removed():addAction(function(party_member)
        self:removePartyMember(party_member)
    end), party:on_party_member_removed())

    self:addPartyMembers(self.party:get_party_members(true))

    return self
end

function PartyMemberDataProvider:destroy()
    ListItemDataProvider.destroy(self)

    self.party = nil
end

---
-- Add a PartyMemberListItem to the data provider.
--
-- @tparam PartyMemberListItem party_member The PartyMemberListItem instance to add.
--
function PartyMemberDataProvider:addPartyMember(party_member)
    self:addPartyMembers(L{party_member})
end

---
-- Add multiple PartyMemberListItem instances to the data provider.
--
-- @tparam {PartyMemberListItem} partyMembers A table containing PartyMemberListItem instances to add.
--
function PartyMemberDataProvider:addPartyMembers(partyMembers)
    local items = partyMembers:map(function(party_member)
        return PartyMemberListItem.new(party_member)
    end):filter(function(item)
        return not self:containsItem(item)
    end)

    self:addItems(items)
end

---
-- Remove a PartyMemberListItem from the data provider.
--
-- @tparam PartyMemberListItem party_member The PartyMemberListItem instance to remove.
--
function PartyMemberDataProvider:removePartyMember(party_member)
    self:removeItem(PartyMemberListItem.new(party_member))
end

return PartyMemberDataProvider
