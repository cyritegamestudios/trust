local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Event = require('cylibs/events/Luvent')
local Padding = require('cylibs/ui/style/padding')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local MenuView = setmetatable({}, {__index = CollectionView })
MenuView.__index = MenuView

function MenuView:onSelectMenuItemAtIndexPath()
    return self.selectMenuItem
end

function MenuView.new(menuItem, viewStack, infoView)
    local buttonHeight = 16

    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = ButtonCollectionViewCell.new(item)
        cell:setItemSize(buttonHeight)
        cell:setUserInteractionEnabled(true)
        cell:setIsSelectable(item:getEnabled())
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(6, 6, 0, 0))), MenuView)

    self:setScrollDelta(buttonHeight)
    self:setAllowsMultipleSelection(false)
    self:setAllowsScrollWrap(true)

    self.menuItem = menuItem
    self.selectMenuItem = Event.newEvent()
    self.views = L{}
    self.viewStack = viewStack
    self.infoView = infoView

    self:setScrollEnabled(false)
    self:setItem(menuItem)
    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

function MenuView:destroy()
    CollectionView.destroy(self)

    if self.backgroundImageView then
        self.backgroundImageView:destroy()
    end

    self.viewStack:dismissAll()
    self.selectMenuItem:removeAllActions()
end

function MenuView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return
    end
end

function MenuView:setItem(menuItem)
    local menuArgs = {}

    local currentView = self.viewStack:getCurrentView()
    if currentView then
        menuArgs = currentView and type(currentView.getMenuArgs) == 'function' and currentView:getMenuArgs()
    end

    if not menuItem.keepViews then
        while self.views:contains(self.viewStack:getCurrentView()) do
            self.viewStack:dismiss()
        end
        self.views = L{}
    end

    self.menuItem = menuItem

    local buttonItems = menuItem:getButtonItems()
    if buttonItems:length() > 0 then
        local buttonHeight = 16
        local menuHeight = buttonHeight * (buttonItems:length()) + 10
        local menuWidth = 112

        if not self:getBackgroundImageView() then
            local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, menuWidth, menuHeight))
            self:setBackgroundImageView(backgroundView)
        end

        self:getBackgroundImageView():setTitle(menuItem:getTitleText() or "")

        self:getBackgroundImageView():setNeedsLayout()
        self:getBackgroundImageView():layoutIfNeeded()

        self:getDataSource():removeAllItems()

        local indexedItems = L{}

        local rowIndex = 1
        for buttonItem in buttonItems:it() do
            local indexedItem = IndexedItem.new(buttonItem, IndexPath.new(1, rowIndex))
            indexedItems:append(indexedItem)
            rowIndex = rowIndex + 1
        end

        self:getDataSource():addItems(indexedItems)

        self:setSize(menuWidth, menuHeight)

        self:setNeedsLayout()
        self:layoutIfNeeded()

        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    local contentView = menuItem:getContentView(menuArgs, self.infoView)
    if contentView then
        self.views:append(contentView)
        self.viewStack:present(contentView)
    end
end

function MenuView:getItem()
    return self.menuItem
end

function MenuView:getViewStack()
    return self.viewStack
end

return MenuView