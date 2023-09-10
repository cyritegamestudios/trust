local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local PartyMemberListItem = setmetatable({}, {__index = TextItem })
PartyMemberListItem.__index = PartyMemberListItem

-- Creates a new PartyMemberListItem instance.
-- @tparam PartyMember party_member The party member data.
-- @treturn PartyMemberListItem The newly created PartyMemberListItem instance.
function PartyMemberListItem.new(party_member)
    local self = setmetatable(TextItem.new(party_member:get_name(), TextStyle.Default.Text), PartyMemberListItem)

    self.partyMember = party_member
    self.partyMemberId = party_member:get_id()
    self.buffIds = party_member:get_buff_ids() or S{}

    return self
end

---
-- Gets the associated PartyMember object.
--
-- @treturn PartyMember The PartyMember object associated with this PartyMemberListItem.
--
function PartyMemberListItem:getPartyMember()
    return self.partyMember
end

---
-- Add a buff ID to the list of buffs for this party member.
--
-- @tparam number buffId The ID of the buff to add.
--
function PartyMemberListItem:addBuff(buffId)
    self.buffIds:add(buffId)
end

---
-- Remove a buff ID from the list of buffs for this party member.
--
-- @tparam number buffId The ID of the buff to remove.
--
function PartyMemberListItem:removeBuff(buffId)
    self.buffIds:remove(buffId)
end

-- Checks if this PartyMemberListItem is equal to another item.
-- @tparam PartyMemberListItem otherItem The other PartyMemberListItem to compare.
-- @treturn bool Returns true if the items are equal, false otherwise.
function PartyMemberListItem:__eq(otherItem)
    return self.partyMemberId == otherItem.partyMemberId
end

return PartyMemberListItem
