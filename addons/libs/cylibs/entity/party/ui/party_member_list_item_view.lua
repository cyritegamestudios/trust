local DisposeBag = require('cylibs/events/dispose_bag')
local ImageListItem = require('cylibs/ui/items/images/image_list_item')
local HorizontalListLayout = require('cylibs/ui/layouts/horizontal_list_layout')
local ListItemDataProvider = require('cylibs/ui/lists/list_item_data_provider')
local ListView = require('cylibs/ui/list_view')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local PartyMemberListItemView = setmetatable({}, {__index = TextListItemView })
PartyMemberListItemView.__index = PartyMemberListItemView

function PartyMemberListItemView.new(item)
    local self = setmetatable(TextListItemView.new(item), PartyMemberListItemView)

    self.statusDataProvider = ListItemDataProvider.new()
    self.disposeBag = DisposeBag.new()

    -- Observe party member buff changes
    self.disposeBag:add(item:getPartyMember():on_gain_buff():addAction(function(p, buffId)
        self.statusDataProvider:addItem(ImageListItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20))
    end), item:getPartyMember():on_gain_buff())

    self.disposeBag:add(item:getPartyMember():on_lose_buff():addAction(function(p, buffId)
        self.statusDataProvider:removeItem(ImageListItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20))
    end), item:getPartyMember():on_lose_buff())

    -- Observe status data provider changes
    self.statusListView = ListView.new(HorizontalListLayout.new(20, 2))
    self.statusListView:set_color(75, 175, 175, 175)

    self.disposeBag:add(self.statusDataProvider:onItemsChanged():addAction(function(items)
        self.statusListView:updateItems(items)
    end), self.statusDataProvider:onItemsChanged())

    self.disposeBag:add(self.statusDataProvider:onItemsAdded():addAction(function(items)
        self.statusListView:addItems(items)
    end), self.statusDataProvider:onItemsAdded())

    self.disposeBag:add(self.statusDataProvider:onItemsRemoved():addAction(function(items)
        self.statusListView:removeItems(items)
    end), self.statusDataProvider:onItemsRemoved())

    self:addChild(self.statusListView)

    local buffItems = item:getPartyMember():get_buff_ids():map(function(buffId)
        return ImageListItem.new(windower.addon_path..'assets/buffs/'..buffId..'.png', 20, 20)
    end)

    self.statusDataProvider:addItems(buffItems)

    return self
end

function PartyMemberListItemView:destroy()
    TextListItemView.destroy(self)

    self.disposeBag:destroy()

    self.statusDataProvider:destroy()
    self.statusListView:destroy()
end

function PartyMemberListItemView:render()
    TextListItemView.render(self)

    local x, y = self:get_pos()
    local width, height = self:get_size()

    self.statusListView:set_pos(x, y + 25)
    self.statusListView:set_size(width, 20)
    self.statusListView:set_visible(self:is_visible())
    self.statusListView:render()
end

return PartyMemberListItemView