local BackgroundView = require('cylibs/ui/views/background/background_view')
local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Event = require('cylibs/events/Luvent')
local MenuItem = require('cylibs/ui/menu/menu_item')
local Padding = require('cylibs/ui/style/padding')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewStack = require('cylibs/ui/views/view_stack')

local MenuView = setmetatable({}, {__index = CollectionView })
MenuView.__index = MenuView

function MenuView:onSelectMenuItemAtIndexPath()
    return self.selectMenuItem
end

function MenuView.new(menuItem, viewStack)
    local buttonHeight = 18

    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = ButtonCollectionViewCell.new(item)
        cell:setItemSize(buttonHeight)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(10, 5, 0, 0)), nil, cursorImageItem), MenuView)

    self:setScrollDelta(buttonHeight)
    self:setAllowsMultipleSelection(false)

    self.menuItem = menuItem
    self.selectMenuItem = Event.newEvent()
    self.views = L{}
    self.viewStack = viewStack

    self:setScrollEnabled(false)
    self:setItem(menuItem)
    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function MenuView:destroy()
    CollectionView.destroy(self)

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

    while self.views:contains(self.viewStack:getCurrentView()) do
        self.viewStack:dismiss()
    end
    self.views = L{}

    self.menuItem = menuItem

    local buttonItems = menuItem:getButtonItems()
    if buttonItems:length() > 0 then
        local buttonHeight = 18
        local menuHeight = buttonHeight * (buttonItems:length() + 1)
        local menuWidth = 115

        self:setBackgroundImageView(nil)

        local backgroundView = BackgroundView.new(Frame.new(0, 0, menuWidth, menuHeight),
                windower.addon_path..'assets/backgrounds/menu_bg_top.png',
                windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
                windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

        self:setBackgroundImageView(backgroundView)

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

    local contentView = menuItem:getContentView(menuArgs)
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