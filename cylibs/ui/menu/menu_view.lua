local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Event = require('cylibs/events/Luvent')
local Padding = require('cylibs/ui/style/padding')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local MenuView = setmetatable({}, {__index = CollectionView })
MenuView.__index = MenuView
MenuView.__type = "MenuView"

function MenuView:onSelectMenuItemAtIndexPath()
    return self.selectMenuItem
end

function MenuView.new(menuItem, viewStack, infoView, showMenu, mediaPlayer)
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
    self:setUserInteractionEnabled(true)

    self.menuItem = menuItem
    self.selectMenuItem = Event.newEvent()
    self.views = L{}
    self.viewStack = viewStack
    self.infoView = infoView
    self.showMenu = showMenu

    local leftArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_left.png', 14, 7)
    self.leftArrowButton = ImageCollectionViewCell.new(leftArrowButtonItem)
    self.leftArrowButton:setPosition(-16, 8)

    local rightArrowButtonItem = ImageItem.new(windower.addon_path..'assets/buttons/button_arrow_right.png', 14, 7)
    self.rightArrowButton = ImageCollectionViewCell.new(rightArrowButtonItem)
    self.rightArrowButton:setPosition(112, 8)

    self:setArrowsVisible(false)

    self:setVisible(false)
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

function MenuView:setArrowsVisible(visible)
    for button in L{ self.leftArrowButton, self.rightArrowButton }:it() do
        if visible then
            self:getContentView():addSubview(button)

            button:setVisible(true)
            button:layoutIfNeeded()
        else
            button:setVisible(false)
            button:removeFromSuperview()
        end
    end
    self:getContentView():setNeedsLayout()
    self:getContentView():layoutIfNeeded()
end

function MenuView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return
    end
end

function MenuView:getPageSize()
    return 14
end

function MenuView:getNumPages()
    return self.pages:keyset():length()
end

function MenuView:createPages(buttonItems)
    self.pages = T{}

    local pageNum = 1

    local index = 1
    while index <= buttonItems:length() do
        self.pages[pageNum] = buttonItems:slice(index, math.min(index + self:getPageSize(), buttonItems:length()))
        index = index + self:getPageSize() + 1
        pageNum = pageNum + 1
    end
end

function MenuView:setPage(pageNum)
    if self.currentPageNum == pageNum then
        return
    end
    self.currentPageNum = pageNum

    local buttonItems = self.pages[pageNum]
    if buttonItems and buttonItems:length() > 0 then
        local buttonHeight = 16
        local menuHeight = buttonHeight * (buttonItems:length()) + 10
        local menuWidth = 112

        if not self:getBackgroundImageView() then
            local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, menuWidth, menuHeight))
            self:setBackgroundImageView(backgroundView)
        end

        self:getBackgroundImageView():setTitle(self.menuItem:getTitleText() or "")

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
end

function MenuView:setItem(menuItem)
    if self.menuItem then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuItem:setMenuIndex(cursorIndexPath.row)
        end
    end

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
    self.currentPageNum = nil

    local buttonItems = menuItem:getButtonItems()
    self:createPages(buttonItems)

    self:setArrowsVisible(buttonItems:length() > 14)

    self:setPage(1)

    local menuIndex = self.menuItem:getMenuIndex()
    if menuIndex then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, menuIndex))
    end

    local contentView = menuItem:getContentView(menuArgs, self.infoView, self.showMenu)
    if contentView then
        self.views:append(contentView)
        self.viewStack:present(contentView)
    end
end

function MenuView:pageLeft()
    local nextPageNum = self.currentPageNum - 1
    if nextPageNum <= 0 then
        nextPageNum = self:getNumPages()
    end
    self:setPage(nextPageNum)
end

function MenuView:pageRight()
    local nextPageNum = self.currentPageNum + 1
    if nextPageNum > self:getNumPages() then
        nextPageNum = 1
    end
    self:setPage(nextPageNum)
end

function MenuView:onMouseEvent(type, x, y, delta)
    return self:getDelegate():onMouseEvent(type, x, y, delta)
end

function MenuView:getItem()
    return self.menuItem
end

function MenuView:getViewStack()
    return self.viewStack
end

return MenuView