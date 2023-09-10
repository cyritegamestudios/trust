local Event = require('cylibs/events/Luvent')
local View = require('cylibs/ui/view')

local ListView = setmetatable({}, {__index = View })
ListView.__index = ListView

---
-- Gets the event object for click events on the list view.
--
-- @treturn Event Returns the event object for click events.
--
function ListView:onClick()
    return self.click
end

---
-- Gets the event object for hovering over an item in the list view.
--
-- @treturn Event Returns the event object for hover events.
--
function ListView:onHover()
    return self.hoverOver
end

---
-- Gets the event object for items changed events on the list view.
--
-- @treturn Event Returns the event object for items changed events.
--
function ListView:onItemsChanged()
    return self.itemsChanged
end

function ListView.new(layout)
    local self = setmetatable(View.new(), ListView)
    self.layout = layout
    self.itemViews = T{}
    self.items = L{} -- in order
    self.events = {}
    self.click = Event.newEvent()
    self.hoverOver = Event.newEvent()
    self.itemsChanged = Event.newEvent()

    self.onClickId = input:onClick():addAction(function(type, x, y, delta, blocked)
        if blocked or not self:is_visible() then
            return false
        end

        -- Mouse left click
        if type == 1 then
            for item, itemView in pairs(self.itemViews) do
                if itemView:hover(x, y) then
                    self:onClick():trigger(item)
                    return false
                end
            end
        end
        return false
    end)
    self.onMoveId = input:onMove():addAction(function(type, x, y, delta, blocked)
        if blocked or not self:is_visible() then
            return false
        end

        if type == 0 then
            for item, itemView in pairs(self.itemViews) do
                if itemView:hover(x, y) then
                    self:onHover():trigger(itemView, item)
                    if itemView:is_highlightable() then
                        itemView:set_highlighted(true)
                    end
                else
                    itemView:set_highlighted(false)
                end
            end
        end
        return false
    end)

    self:set_color(0, 0, 0, 0)

    return self
end

function ListView:destroy()
    input:onClick():removeAction(self.onClickId)
    input:onMove():removeAction(self.onMoveId)

    self:onClick():removeAllActions()
    self:onHover():removeAllActions()
    self:onItemsChanged():removeAllActions()

    self.layout:destroy()

    self:removeAllItems()

    for _, itemView in pairs(self.itemViews) do
        itemView:destroy()
    end

    View.destroy(self)
end

function ListView:getItemView(item)
    for existingItem, itemView in pairs(self.itemViews) do
        if existingItem == item then
            return itemView
        end
    end
    return nil
end

function ListView:getItem(identifier)
    local match = self.items:filter(function(item) return item:getIdentifier() == identifier  end)
    if match:length() > 0 then
        return match[1]
    end
    return nil
end

function ListView:numItems()
    return self.items:length()
end

---
-- Adds a list of items to the list view.
--
-- @tparam list items A list of ListItem to add.
--
function ListView:addItems(items)
    if items:length() > 19 then
        print('Unable to add over 19 items to ListView.')
        return
    end
    for item in items:it() do
        if not self:contains(item) then
            local constructor = item:getViewConstructor()
            if constructor then
                local itemView = constructor(item)
                itemView:set_visible(self:is_visible())

                self.itemViews[item] = itemView
                self.items:append(item)

                self:addChild(itemView)
            end
        end
    end
    self:render()
end

---
-- Adds an item to the list view.
--
-- @tparam ListItem item The item to add to the list.
--
function ListView:addItem(item)
    self:addItems(L{item})
end

function ListView:contains(item)
    return self:getItemView(item) ~= nil
end

function ListView:indexOf(item)
    for i = 1, self.items:length() do
        local otherItem = self.items[i]
        if otherItem and otherItem == item then
            return i
        end
    end
    return -1
end

function ListView:removeItems(items)
    for item in items:it() do
        local itemView = self:getItemView(item)
        if itemView ~= nil then
            self:removeChild(itemView)
            itemView:destroy()
            for key, value in pairs(self.itemViews) do
                if key == item then
                    self.itemViews[key] = nil
                end
            end
            --self.itemViews[item] = nil
        end
    end
    self.items = self.items:filter(function(item) return not items:contains(item)  end)
    self:render()
end

function ListView:removeAllItems()
    self:removeAllChildren()

    for _, itemView in pairs(self.itemViews) do
        itemView:destroy()
    end

    self.itemViews = {}
    self.items = L{}
end

function ListView:updateItems(items)
    for item in items:it() do
        self:updateItemView(item)
    end
end

function ListView:updateItemView(item)
    local itemView = self:getItemView(item)
    if itemView then
        itemView:setItem(item)
        self:render()
    end
end

function ListView:deselectAllItems()
    for _, itemView in pairs(self.itemViews) do
        if itemView:is_selectable() then
            itemView:set_selected(false)
            itemView:render()
        end
    end
end

function ListView:selectItem(item)
    local itemView = self:getItemView(item)
    if itemView then
        if itemView:is_selectable() then
            itemView:set_selected(true)
        end
        self:render()
    end
end

function ListView:render()
    View.render(self)

    self.layout:layout(self.itemViews, self.items)

    local layoutWidth, layoutHeight = self.layout:getSize()
    self:set_size(layoutWidth, layoutHeight)
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate of the new position.
-- @tparam number y The y-coordinate of the new position.
--
function ListView:set_pos(x, y)
    View.set_pos(self, x, y)

    self.layout:setOffset(x, y)
end

return ListView
