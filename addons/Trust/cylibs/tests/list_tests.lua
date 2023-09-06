local CyTest = require('cylibs/tests/cy_test')
local Event = require('cylibs/events/Luvent')
local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local VerticalListLayout = require('cylibs/ui/layouts/vertical_list_layout')

local ListTests = {}
ListTests.__index = ListTests

function ListTests:onCompleted()
    return self.completed
end

function ListTests.new(listView)
    local self = setmetatable({}, ListTests)
    self.listView = listView
    self.shouldDestroy = listView == nil
    self.completed = Event.newEvent()
    return self
end

function ListTests:destroy()
    self.listView:destroy()

    self.completed:removeAllActions()
end

function ListTests:run()
    self:testLists()
end

-- Tests

function ListTests:testLists()
    self.listView = self.listView

    if self.listView == nil then
        self.listView = ListView.new(VerticalListLayout.new(200, 5))
        self.listView:set_color(175, 0, 0, 0)
        self.listView:set_pos(500, 200)
    end

    self.listView:addItem(ListItem.new({text = 'Item1', height = 30}, ListViewItemStyle.DarkMode.Header, "Item1", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = 'Item2', height = 30}, ListViewItemStyle.DarkMode.Header, "Item2", TextListItemView.new))

    self.listView:render()

    CyTest.assert(self.listView:numItems() == 2, "getNumItems() should be 2")

    local item1 = self.listView:getItem('Item1')
    local item2 = self.listView:getItem('Item2')

    CyTest.assert(item1 ~= nil and self.listView:indexOf(item1) == 1, "indexOf(item1) should be 1")
    CyTest.assert(item2 ~= nil and self.listView:indexOf(item2) == 2, "indexOf(item2) should be 2")
    CyTest.assert(item1:getIdentifier() == 'Item1', "getItem() Item1 should exist")
    CyTest.assert(item2:getIdentifier() == 'Item2', "getItem() Item2 should exist")

    local itemView1 = self.listView:getItemView(item1)
    local itemView2 = self.listView:getItemView(item2)

    CyTest.assert(itemView1 ~= nil and self.listView:containsChild(itemView1), "ListView should containChild(itemView1)")
    CyTest.assert(itemView2 ~= nil and self.listView:containsChild(itemView2), "ListView should containChild(itemView2)")

    self.listView:removeAllItems()

    CyTest.assert(itemView1:is_destroyed(), "ItemView1 should be destroyed after removeAllItems()")
    CyTest.assert(itemView2:is_destroyed(), "ItemView2 should be destroyed after removeAllItems()")

    CyTest.assert(self.listView:numItems() == 0, "getNumItems() should be 0 after removeAllItems()")
    CyTest.assert(self.listView:getChildren():length() == 0, "getChildren() length should be 0 after removeAllItems()")

    self.listView:addItem(ListItem.new({text = 'Item3', height = 30}, ListViewItemStyle.DarkMode.Header, "Item3", TextListItemView.new))

    local item3 = self.listView:getItem('Item3')

    CyTest.assert(item3 ~= nil and self.listView:indexOf(item3) == 1, "indexOf(item3) should be 1")
    CyTest.assert(item3:getIdentifier() == 'Item3', "getItem() Item3 should exist")

    self.listView:removeAllItems()

    if self.shouldDestroy then
        self.listView:destroy()

        CyTest.assert(self.listView:is_destroyed(), "ListView should be destroyed after destroy()")
        CyTest.assert(self.listView:numItems() == 0, "getNumItems() should be 0 after destroy()")
    end

    self:onCompleted():trigger(true)
end

return ListTests