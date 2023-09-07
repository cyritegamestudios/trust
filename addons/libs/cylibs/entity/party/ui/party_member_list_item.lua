local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local PartyMemberListItemView = require('cylibs/entity/party/ui/party_member_list_item_view')

local PartyMemberListItem = setmetatable({}, {__index = ListItem })
PartyMemberListItem.__index = PartyMemberListItem

-- Creates a new PartyMemberListItem instance.
-- @tparam PartyMember party_member The party member data.
-- @treturn PartyMemberListItem The newly created PartyMemberListItem instance.
function PartyMemberListItem.new(party_member)
    local self = setmetatable(ListItem.new({ text = party_member:get_name(), height = 60 }, ListViewItemStyle.DarkMode.Text, party_member:get_id(), PartyMemberListItemView.new), PartyMemberListItem)

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
    return self:getIdentifier() == otherItem:getIdentifier()
end

return PartyMemberListItem
