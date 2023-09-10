local CyTest = require('cylibs/tests/cy_test')
local Event = require('cylibs/events/Luvent')
local ListItem = require('cylibs/ui/list_item')
local ListItemDataProvider = require('cylibs/ui/lists/list_item_data_provider')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local Party = require('cylibs/entity/party')
local PartyMember = require('cylibs/entity/party_member')
local PartyMemberDataProvider = require('cylibs/entity/party/ui/party_member_data_provider')
local PartyMemberListItem = require('cylibs/entity/party/ui/party_member_list_item')
local PartyMemberListItemView = require('cylibs/entity/party/ui/party_member_list_item_view')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local VerticalListLayout = require('cylibs/ui/layouts/vertical_list_layout')

local PartyTests = {}
PartyTests.__index = PartyTests

function PartyTests:onCompleted()
    return self.completed
end

function PartyTests.new(listView)
    local self = setmetatable({}, PartyTests)
    self.listView = listView
    self.shouldDestroy = listView == nil
    self.completed = Event.newEvent()
    return self
end

function PartyTests:destroy()
    self.listView:destroy()

    self.completed:removeAllActions()
end

function PartyTests:run()
    self:testPartyDataProvider()

    self:onCompleted():trigger(true)
end

-- Tests

function PartyTests:testPartyDataProvider()

end

return PartyTests