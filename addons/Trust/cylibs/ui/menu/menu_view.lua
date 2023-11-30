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

local MenuView = setmetatable({}, {__index = CollectionView })
MenuView.__index = MenuView

function MenuView:onSelectMenuItemAtIndexPath()
    return self.selectMenuItem
end

function MenuView.new(menuItem)
    local buttonItems = menuItem:getButtonItems()
    local buttonHeight = 18
    local menuHeight = buttonHeight * (buttonItems:length() + 1)
    local menuWidth = 115

    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = ButtonCollectionViewCell.new(item)
        cell:setItemSize(buttonHeight)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(10, 5, 0, 0))), MenuView)

    self.menuItem = menuItem
    self.selectMenuItem = Event.newEvent()

    local backgroundView = BackgroundView.new(Frame.new(0, 0, menuWidth, menuHeight),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

    self:setBackgroundImageView(backgroundView)
    self:setScrollEnabled(false)
    self:setSize(menuWidth, menuHeight)

    self.cursor = ImageCollectionViewCell.new(ImageItem.new(windower.addon_path..'assets/icons/cursor.png', 37, 24))

    self:getContentView():addSubview(self.cursor)

    self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local cell = self.dataSource:cellForItemAtIndexPath(indexPath)
        if cell then
            self.cursor:setPosition(cell:getPosition().x - 35, cell:getPosition().y - 2)
            self.cursor:setNeedsLayout()
            self.cursor:layoutIfNeeded()
        end
    end)

    local indexedItems = L{}

    local rowIndex = 1
    for buttonItem in buttonItems:it() do
        local indexedItem = IndexedItem.new(buttonItem, IndexPath.new(1, rowIndex))
        indexedItems:append(indexedItem)
        rowIndex = rowIndex + 1
    end

    dataSource:addItems(indexedItems)

    self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function MenuView:destroy()
    CollectionView.destroy(self)

    self.selectMenuItem:removeAllActions()
end

function MenuView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return
    end
end

function MenuView:onKeyboardEvent(key, pressed, flags, blocked)
    if not self:isVisible() or blocked then
        return blocked
    end
    if pressed then
        local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
        if selectedIndexPaths:length() > 0 then
            local currentIndexPath = selectedIndexPaths[1]
            if key == 208 then
                local nextIndexPath = IndexPath.new(currentIndexPath.section, math.min(currentIndexPath.row + 1, self:getDataSource():numberOfItemsInSection(currentIndexPath.section)))
                self:getDelegate():selectItemAtIndexPath(nextIndexPath)
                return true
            elseif key == 200 then
                local nextIndexPath = IndexPath.new(currentIndexPath.section, math.max(currentIndexPath.row - 1, 1))
                self:getDelegate():selectItemAtIndexPath(nextIndexPath)
                return true
            elseif key == 28 then
                local item = self:getDataSource():itemAtIndexPath(currentIndexPath)
                if item then
                    self:onSelectMenuItemAtIndexPath():trigger(self, item:getTextItem(), currentIndexPath)
                end
            end
        end
    end
    return L{200, 208}:contains(key)
end

function MenuView:getItem()
    return self.menuItem
end

return MenuView