local CollectionViewDelegate = require('cylibs/ui/collection_view/collection_view_delegate')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Frame = require('cylibs/ui/views/frame')
local ScrollView = require('cylibs/ui/scroll_view/scroll_view')
local SoundTheme = require('cylibs/sounds/sound_theme')

local CollectionView = setmetatable({}, {__index = ScrollView })
CollectionView.__index = CollectionView
CollectionView.__type = "CollectionView"
CollectionView.__class = "CollectionView"

local defaultStyle

function CollectionView.defaultStyle()
    return defaultStyle
end

function CollectionView.setDefaultStyle(style)
    defaultStyle = style
end

local defaultBackgroundStyle

function CollectionView.defaultBackgroundStyle()
    return defaultBackgroundStyle
end

function CollectionView.setDefaultBackgroundStyle(style)
    defaultBackgroundStyle = style
end

---
-- Creates a new CollectionView instance with the specified data source and layout.
--
-- @tparam CollectionViewDataSource dataSource The data source providing content for the collection view.
-- @tparam CollectionViewLayout layout The layout strategy for arranging items in the collection view.
-- @tparam CollectionViewDelegate delegate (optional) The delegate for interacting with items in the collection view.
-- @tparam CollectionViewStyle style The style used to render the CollectionView.
-- @tparam MediaPlayer mediaPlayer The media player.
-- @tparam SoundTheme soundTheme The sound theme.
-- @treturn CollectionView The newly created CollectionView instance.
--
function CollectionView.new(dataSource, layout, delegate, style, mediaPlayer, soundTheme)
    style = style or CollectionView.defaultStyle()

    local self = setmetatable(ScrollView.new(Frame.zero(), style), CollectionView)

    self.layout = layout
    self.dataSource = dataSource
    self.delegate = delegate or CollectionViewDelegate.new(self)
    self.style = style
    self.mediaPlayer = mediaPlayer
    self.soundTheme = soundTheme
    self.allowsMultipleSelection = false
    self.allowsCursorSelection = false
    self.cursorImageItem = style:getCursorItem()

    if self.cursorImageItem then
        self.selectionBackground = ImageCollectionViewCell.new(self.cursorImageItem)

        self:getContentView():addSubview(self.selectionBackground)

        self:getDisposeBag():addAny(L{ self.selectionBackground })

        self.selectionBackground:setVisible(false)
        self.selectionBackground:setNeedsLayout()
        self.selectionBackground:layoutIfNeeded()

        self.delegate:didSelectItemAtIndexPath():addAction(function(indexPath)
            self:getDelegate():setCursorIndexPath(indexPath)
        end)
    end

    self:getDisposeBag():addAny(L{ self.delegate, self.dataSource, self.layout, self.contentView })

    self.dataSource:onItemsWillChange():addAction(function(addedIndexPaths, removedIndexPaths, updatedIndexPaths)
        for _, indexPath in pairs(removedIndexPaths) do
            self:getDelegate():deleteItemAtIndexPath(indexPath)
        end
    end)
    self.dataSource:onItemsChanged():addAction(function(addedIndexPaths, removedIndexPaths, updatedIndexPaths)
        self.layout:setNeedsLayout(self, addedIndexPaths, removedIndexPaths, updatedIndexPaths)

        if removedIndexPaths:contains(self:getDelegate():getCursorIndexPath()) then
            if self:getDataSource():numberOfItemsInSection(1) > 0 then
                self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
            end
        end
        self:moveCursorToIndexPath()
    end)
    self:getDisposeBag():add(self.delegate:didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
        self:moveCursorToIndexPath(cursorIndexPath)
    end), self.delegate:didMoveCursorToItemAtIndexPath())

    return self
end

---
-- Moves the cursor to the current cursor index path.
--
--  @tparam IndexPath cursorIndexPath Cursor index path, or the current cursor index path if nil
--
function CollectionView:moveCursorToIndexPath(cursorIndexPath)
    if not self.selectionBackground then
        return
    end
    local isCursorVisible = false

    cursorIndexPath = cursorIndexPath or self:getDelegate():getCursorIndexPath()
    if cursorIndexPath and self:getDataSource():itemAtIndexPath(cursorIndexPath) then
        local cell = self:getDataSource():cellForItemAtIndexPath(cursorIndexPath)
        if cell then
            self.selectionBackground:setPosition(cell:getPosition().x - self.cursorImageItem:getSize().width - 7, cell:getPosition().y + (cell:getSize().height - self.cursorImageItem:getSize().height) / 2)
            self.selectionBackground:setSize(self.cursorImageItem:getSize().width, self.cursorImageItem:getSize().height)
            isCursorVisible = self:hasFocus() and self:isCursorEnabled()
        end
    end

    self.selectionBackground:setVisible(isCursorVisible)
    self.selectionBackground:setNeedsLayout()
    self.selectionBackground:layoutIfNeeded()
end

---
-- Returns the data source associated with the collection view.
--
-- @treturn CollectionViewDataSource The data source.
--
function CollectionView:getDataSource()
    return self.dataSource
end

---
-- Returns the delegate associated with the collection view.
--
-- @treturn CollectionViewDelegate The delegate.
--
function CollectionView:getDelegate()
    return self.delegate
end

---
-- Gets the current value of the `allowsMultipleSelection` property.
--
-- @treturn boolean The current value of `allowsMultipleSelection`.
--
function CollectionView:getAllowsMultipleSelection()
    return self.allowsMultipleSelection
end

---
-- Sets the `allowsMultipleSelection` property to the specified value.
--
-- @tparam boolean allowsMultipleSelection The new value for `allowsMultipleSelection`.
--
function CollectionView:setAllowsMultipleSelection(allowsMultipleSelection)
    self.allowsMultipleSelection = allowsMultipleSelection
end

---
-- Gets the current value of the `allowsCursorSelection` property. If `true` items will be selected
-- when the cursor is next to them.
--
-- @treturn boolean The current value of `allowsCursorSelection`.
--
function CollectionView:getAllowsCursorSelection()
    return self.allowsCursorSelection
end

---
-- Sets the `allowsCursorSelection` property to the specified value.
--
-- @tparam boolean allowsCursorSelection The new value for `allowsCursorSelection`.
--
function CollectionView:setAllowsCursorSelection(allowsCursorSelection)
    self.allowsCursorSelection = allowsCursorSelection
end

---
-- Sets whether scrolling should wrap around once it reaches the end.
--
-- @tparam boolean allowsScrollWrap The new value for `allowsScrollWrap`.
--
function CollectionView:setAllowsScrollWrap(allowsScrollWrap)
    self.allowsScrollWrap = allowsScrollWrap
end

---
-- Set a new scroll delta value.
--
-- @tparam number delta The new scroll delta value.
--
function CollectionView:setScrollDelta(delta)
    ScrollView.setScrollDelta(self, delta + self.layout:getItemSpacing())
end

---
-- Set a new scroll delta value.
--
-- @tparam number delta The new scroll delta value.
--
function CollectionView:setScrollDelta(delta)
    ScrollView.setScrollDelta(self, delta + self.layout:getItemSpacing())
end

---
-- Sets the content offset when scrolling up/right.
--
-- @tparam ScrollBar scrollBar The scroll bar that was clicked.
--
function CollectionView:scrollForward(scrollBar)
    local scrollDelta = self:getScrollDelta()

    local currentIndexPath = self:getDelegate():getCursorIndexPath()
    if currentIndexPath then
        local nextIndexPath = self:getDataSource():getNextIndexPath(currentIndexPath, false)
        if nextIndexPath.section > currentIndexPath.section then
            local sectionHeaderView = self:getDataSource():headerViewForSection(nextIndexPath.section)
            if sectionHeaderView then
                scrollDelta = scrollDelta + sectionHeaderView:getItemSize()
            end
        end
        if self:getDelegate():getCursorIndexPath() then
            self:getDelegate():setCursorIndexPath(nextIndexPath)
        end
    end

    local newContentOffset = Frame.new(self:getContentOffset().x, self:getContentOffset().y, 0, 0)
    if scrollBar == self.horizontalScrollBar then
        newContentOffset.x = math.max(self:getContentOffset().x - scrollDelta, -self:getContentSize().width / 2)
    else
        local minY = -(self:getContentSize().height + self:getPadding().bottom - self:getSize().height)
        newContentOffset.y = math.max(self:getContentOffset().y - scrollDelta, minY)
    end
    self:setContentOffset(newContentOffset.x, newContentOffset.y)
end

---
-- Sets the content offset when scrolling down/left.
--
-- @tparam ScrollBar scrollBar The scroll bar that was clicked.
--
function CollectionView:scrollBack(scrollBar)
    local scrollDelta = self:getScrollDelta()

    local currentIndexPath = self:getDelegate():getCursorIndexPath()
    if currentIndexPath then
        local nextIndexPath = self:getDataSource():getNextIndexPath(currentIndexPath, false)
        if nextIndexPath.section > currentIndexPath.section then
            local sectionHeaderView = self:getDataSource():headerViewForSection(nextIndexPath.section)
            if sectionHeaderView then
                scrollDelta = scrollDelta + sectionHeaderView:getItemSize()
            end
        end
        if self:getDelegate():getCursorIndexPath() then
            self:getDelegate():setCursorIndexPath(self:getDataSource():getPreviousIndexPath(currentIndexPath, false))
        end
    end

    local newContentOffset = Frame.new(self:getContentOffset().x, self:getContentOffset().y, 0, 0)
    if scrollBar == self.horizontalScrollBar then
        newContentOffset.x = math.min(self:getContentOffset().x + scrollDelta, 0)
    else
        newContentOffset.y = math.min(self:getContentOffset().y + scrollDelta, 8)
    end
    self:setContentOffset(newContentOffset.x, newContentOffset.y)
end

---
-- Returns whether the cursor is enabled.
--
-- @treturn boolean Whether the cursor is enabled.
--
function CollectionView:isCursorEnabled()
    return true
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function CollectionView:layoutIfNeeded()
    ScrollView.layoutIfNeeded(self)

    self.layout:layoutSubviews(self)

    self:moveCursorToIndexPath()

    return true
end

function CollectionView:setHasFocus(hasFocus)
    ScrollView.setHasFocus(self, hasFocus)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function CollectionView:playSoundsForKey(keyName)
    if self.mediaPlayer == nil or self.soundTheme == nil or self.isScrolling then
        return
    end
    if keyName == 'Escape' then
        self.mediaPlayer:playSound(self.soundTheme:getSoundForAction(SoundTheme.UI.Menu.Escape))
    elseif S{ 'Up', 'Down', 'Left', 'Right' }:contains(keyName) then
        self.mediaPlayer:playSound(self.soundTheme:getSoundForAction(SoundTheme.UI.Menu.Cursor))
    end
end

function CollectionView:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or ScrollView.onKeyboardEvent(self, key, pressed, flags, blocked)
    if not self:isVisible() or blocked or self.destroyed then
        return blocked
    end
    if pressed then
        local keyName = Keyboard.input():getKey(key, flags)
        
        self:playSoundsForKey(keyName)

        local currentIndexPath = self:getDelegate():getCursorIndexPath()
        if currentIndexPath then
            if key == 208 then
                self.isScrolling = true
                if self:canScroll() then
                    local nextIndexPath = self:getDataSource():getNextIndexPath(currentIndexPath, self.allowsScrollWrap)
                    local cell = self:getDataSource():cellForItemAtIndexPath(nextIndexPath)
                    if not cell:isVisible() then
                        self:scrollDown()
                    end
                    self:getDelegate():setCursorIndexPath(nextIndexPath)
                end
                return true
            elseif key == 200 then
                self.isScrolling = true
                if self:canScroll() then
                    local nextIndexPath = self:getDataSource():getPreviousIndexPath(currentIndexPath, self.allowsScrollWrap)
                    local cell = self:getDataSource():cellForItemAtIndexPath(nextIndexPath)
                    if not cell:isVisible() then
                        self:scrollUp()
                    else
                        local sectionHeader = self:getDataSource():headerViewForSection(nextIndexPath.section)
                        if sectionHeader and not sectionHeader:isVisible() then
                            self:scrollUp()
                        end
                    end
                    self:getDelegate():setCursorIndexPath(nextIndexPath)
                end
                return true
            elseif key == 28 then
                if self.mediaPlayer and self.soundTheme then
                    if self:getDelegate():shouldSelectItemAtIndexPath(self:getDelegate():getCursorIndexPath()) then
                        self.mediaPlayer:playSound(self.soundTheme:getSoundForAction(SoundTheme.UI.Menu.Enter))
                    end
                end
                self:getDelegate():selectItemAtIndexPath(self:getDelegate():getCursorIndexPath())
            end
        end
    else
        self.isScrolling = false
    end
    return L{200, 208}:contains(key)
end

function CollectionView:onMouseEvent(type, x, y, delta)
    if self:getDelegate():onMouseEvent(type, x, y, delta) then
        return true
    end
    return ScrollView.onMouseEvent(self, type, x, y, delta)
end

return CollectionView