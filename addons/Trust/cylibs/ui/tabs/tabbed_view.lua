local VerticalListLayout = require('cylibs/ui/layouts/vertical_list_layout')
local ListView = require('cylibs/ui/list_view')
local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local View = require('cylibs/ui/view')

---
-- @module TabbedView
--

local TabbedView = setmetatable({}, {__index = View })
TabbedView.__index = TabbedView

TabbedView.Style = {
    DarkMode = {
        -- Default style for headers in light mode
        Header = ListViewItemStyle.new(
                {alpha = 0, red = 0, green = 0, blue = 0},
                {alpha = 0, red = 0, green = 0, blue = 0},
                "Arial",
                12,
                {red = 255, green = 255, blue = 255},
                {red = 205, green = 205, blue = 205},
                2,
                1,
                255,
                true
        ),
        -- Default style for text in light mode
        Text = ListViewItemStyle.new(
                {alpha = 0, red = 0, green = 0, blue = 0},
                {alpha = 0, red = 0, green = 0, blue = 0},
                "Arial",
                12,
                {red = 255, green = 255, blue = 255},
                {red = 205, green = 205, blue = 205},
                2,
                0,
                0,
                false
        )
    }
}

---
-- Creates a new TabbedView instance.
--
-- @tparam T styleSettings Style settings for the TabbedView.
--
-- @treturn TabbedView The newly created TabbedView instance.
--
function TabbedView.new(tabItems)
    local self = setmetatable(View.new(), TabbedView)

    self.views = T{}
    self.tabs = T{}
    self.activeTabIndex = 1
    self.tabWidth = 120
    self.padding = 5
    self.tabListView = ListView.new(VerticalListLayout.new(self.tabWidth, 25))

    self:set_color(150, 0, 0, 0)
    self:addChild(self.tabListView)

    self.tabListView:set_color(0, 0, 0, 0)
    self.tabListView:onClick():addAction(function(item)
        local tabIndex = self.tabListView:indexOf(item)
        if tabIndex ~= -1 then
            self:switchToTab(tabIndex)
            self:render()
        end
    end)
    self.tabListView:onItemsChanged():addAction(function(_)
        self:render()
    end)

    local tabIndex = 1
    for tabItem in tabItems:it() do
        self:addChild(tabItem:getView())

        tabItem:getView():set_visible(false)
        self.views[tabIndex] = tabItem:getView()

        local tabLabelItem = ListItem.new({text = tabItem:getTabName():upper(), height = 25, tabName = tabItem:getTabName(), highlightable = true, selectable = true}, TabbedView.Style.DarkMode.Header, tabItem:getTabName(), TextListItemView.new)

        self.tabs[tabIndex] = tabLabelItem
        self.tabListView:addItem(tabLabelItem)

        tabIndex = tabIndex + 1
    end

    return self
end

function TabbedView:removeAllViews()
    self:removeAllChildren()

    for tabIndex, view in pairs(self.views) do
        view:destroy()
    end

    self.tabListView:removeAllItems()

    self.views = T{}
    self.tabs = T{}
    self.activeTabIndex = 1
end

---
-- Destroys the view, cleaning up its resources.
--
function TabbedView:destroy()
    View.destroy(self)

    self:removeAllViews()

    self.tabListView:destroy()
end

---
-- Switches to the view at the specified tab index.
--
-- @tparam number tabIndex The index of the tab to switch to.
--
function TabbedView:switchToTab(tabIndex)
    if self.tabs[tabIndex] then
        self.activeTabIndex = tabIndex

        self:render()
    end
end

---
-- Gets the currently active view in the tabbed view.
--
-- @treturn View|nil Returns the active view or `nil` if there are no tabs or if the active tab index is out of bounds.
--
function TabbedView:getActiveView()
    return self.views[self.activeTabIndex]
end

---
-- Gets the tab item at the specified index.
--
-- @tparam number tabIndex The index of the tab to retrieve.
-- @treturn TabItem|nil Returns the tab item at the specified index or `nil` if the index is out of bounds.
--
function TabbedView:getTabAtIndex(tabIndex)
    return self.tabs[tabIndex]
end


function TabbedView:getNumTabs()
    return #self.tabs:keyset()
end

---
-- Renders the active view of the tabbed interface.
--
function TabbedView:render()
    View.render(self)

    local x, y = self:get_pos()
    local width, height = self:get_size()

    self.tabListView:set_pos(x + 5, y + 5)
    self.tabListView:deselectAllItems()
    self.tabListView:selectItem(self.tabs[self.activeTabIndex])
    self.tabListView:set_visible(self:is_visible())
    self.tabListView:render()

    local activeView = self.views[self.activeTabIndex]
    if activeView then
        for _, view in ipairs(self.views) do
            if view == activeView then
                view:set_pos(x + self.tabWidth + self.padding, y + self.padding)
                view:set_size(width - self.tabWidth - 2 * self.padding, height - 2 * self.padding)
                view:set_visible(true and self:is_visible())
                view:render()
            else
                view:set_visible(false)
                view:render()
            end
        end
    else
        print("No active view to render.")
    end
end

return TabbedView
