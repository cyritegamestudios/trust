local Color = require('cylibs/ui/views/color')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

---
-- @module TabbedView
--
local TabbedView = setmetatable({}, {__index = View })
TabbedView.__index = TabbedView
TabbedView.__type = "TabbedView"

TabbedView.Style = {
    Header = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            12,
            Color.white,
            Color.lightGrey,
            8,
            1,
            255,
            true
    ),
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            12,
            Color.white,
            Color.lightGrey,
            2,
            0,
            0,
            false
    )
}

---
-- Creates a new TabbedView instance.
--
-- @tparam T styleSettings Style settings for the TabbedView.
--
-- @treturn TabbedView The newly created TabbedView instance.
--
function TabbedView.new(frame)
    local self = setmetatable(View.new(frame), TabbedView)

    self.views = {}
    self.contentViewPadding = Padding.new(0, 0, 0, 0)
    self.selectedIndex = nil
    self.selectedView = nil

    self.tabBarDataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    self.tabBarWidth = 130
    self.tabBarHeight = 40
    self.tabBarView = CollectionView.new(self.tabBarDataSource, VerticalFlowLayout.new(0))

    self.tabBarView:setBackgroundColor(Color.clear)
    self.tabBarView:setSize(self.tabBarWidth, frame.height)

    self:addSubview(self.tabBarView)

    local selectionBackgroundItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', self.tabBarWidth, self.tabBarHeight)
    selectionBackgroundItem:setAlpha(125)

    self.selectionBackground = ImageCollectionViewCell.new(selectionBackgroundItem)

    self:addSubview(self.selectionBackground)

    self:getDisposeBag():addAny(L{ self.tabBarView, self.selectionBackground })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    -- Add observers
    self:getDisposeBag():add(self.tabBarView:getDelegate():didSelectItemAtIndexPath():addAction(function(_, indexPath)
        self:selectTab(indexPath.row)
    end), self.tabBarView:getDelegate():didSelectItemAtIndexPath())

    return self
end

---
-- Destroys the view, cleaning up its resources.
--
function TabbedView:destroy()
    View.destroy(self)

    for _, view in pairs(self.views) do
        view:destroy()
    end
end

-- Add a tab to the TabBarController
--
-- @tparam View view The view associated with the tab.
-- @tparam string title The title of the tab.
function TabbedView:addTab(view, title)
    local tabIndex = self.tabBarDataSource:numberOfItemsInSection(1) + 1
    self.tabBarDataSource:addItem(TextItem.new(string.upper(title), TabbedView.Style.Header), IndexPath.new(1, tabIndex))

    view:setVisible(false)

    table.insert(self.views, tabIndex, view)
end

-- Select a specific tab by its index
--
-- @tparam number index The index of the tab to select.
function TabbedView:selectTab(index)
    if self.selectedView then
        self.selectedView:removeFromSuperview()
        self.selectedView:setVisible(false)
        self.selectedView:layoutIfNeeded()
    end

    self.selectedIndex = index
    self.selectedView = self.views[self.selectedIndex]
    if self.selectedView then
        self:addSubview(self.selectedView)

        self.selectedView:setVisible(true)

        local item = self.tabBarView:getDataSource():itemAtIndexPath(IndexPath.new(1, index))
        self.tabBarView:getDelegate():selectItemAtIndexPath(item, IndexPath.new(1, index))

        self.selectionBackground:setPosition(-5, (index - 1) * self.tabBarHeight)
        self.selectionBackground:layoutIfNeeded()

        self:setNeedsLayout()
        self:layoutIfNeeded()
    end
end

function TabbedView:layoutIfNeeded()
    self.tabBarView:setPosition(0, 0)
    self.tabBarView:setSize(self.tabBarWidth, self.frame.height)

    if self.selectedView then
        self.selectedView:setPosition(self.tabBarWidth + self.contentViewPadding.left, self.contentViewPadding.top)
        self.selectedView:setSize(self.frame.width - self.tabBarWidth - self.contentViewPadding.left - self.contentViewPadding.right,
                self.frame.height - self.contentViewPadding.left - self.contentViewPadding.right)
        self.selectedView:setVisible(true)
    end

    View.layoutIfNeeded(self)
end


return TabbedView
