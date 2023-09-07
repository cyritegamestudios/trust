local DisposeBag = require('cylibs/events/dispose_bag')
local ListView = require('cylibs/ui/list_view')
local PartyMemberDataProvider = require('cylibs/entity/party/ui/party_member_data_provider')

local PartyMemberView = setmetatable({}, {__index = ListView })
PartyMemberView.__index = PartyMemberView

---
-- Creates a new PartyMemberView.
--
-- @tparam table party The party data.
-- @tparam Layout layout The layout for the view.
-- @treturn PartyMemberView The newly created PartyMemberView instance.
--
function PartyMemberView.new(party, layout)
    local self = setmetatable(ListView.new(layout), PartyMemberView)

    self.disposeBag = DisposeBag.new()

    self.dataProvider = PartyMemberDataProvider.new(party)

    -- Add event actions
    self.disposeBag:add(self.dataProvider:onItemsAdded():addAction(function(items)
        self:addItems(items)
    end), self.dataProvider:onItemsAdded())

    self.disposeBag:add(self.dataProvider:onItemsRemoved():addAction(function(items)
        self:removeItems(items)
    end), self.dataProvider:onItemsRemoved())

    self.disposeBag:add(self.dataProvider:onItemsChanged():addAction(function(items)
        self:updateItems(items)
    end), self.dataProvider:onItemsChanged())

    -- Add initial items
    self:addItems(self.dataProvider:getItems())

    return self
end

---
-- Destroys the PartyMemberView, cleaning up any resources.
--
function PartyMemberView:destroy()
    ListView.destroy(self)

    self.disposeBag:destroy()
    self.dataProvider:destroy()
end

return PartyMemberView