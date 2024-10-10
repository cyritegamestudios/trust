local DisposeBag = require('cylibs/events/dispose_bag')
local Keyboard = require('cylibs/ui/input/keyboard')
local FocusManager = require('cylibs/ui/focus/focus_manager')
local MenuView = require('cylibs/ui/menu/menu_view')

local Menu =  {}
Menu.__index = Menu
Menu.__type = "Menu"


function Menu.new(contentViewStack, viewStack, infoView)
    local self = setmetatable({}, Menu)

    self.buttonHeight = 16
    self.isChatOpen = false
    self.disposeBag = DisposeBag.new()
    self.menuItemStack = L{}

    self.contentViewStack = contentViewStack
    self.viewStack = viewStack
    self.infoView = infoView

    self.disposeBag:addAny(L{ self.viewStack })

    self.disposeBag:add(viewStack:onStackSizeChanged():addAction(function(stackSize)
        if stackSize > 0 then
            for key in L{'up','down','left','right','enter','numpadenter'}:it() do
                windower.send_command('bind %s block':format(key))
            end
            self.infoView:setVisible(true)
            self.infoView:layoutIfNeeded()
        end
    end), viewStack:onStackSizeChanged())

    self.disposeBag:add(viewStack:onEmpty():addAction(function(_)
        for key in L{'up','down','left','right','enter','numpadenter'}:it() do
            windower.send_command('unbind %s':format(key))
        end
        self.infoView:setVisible(false)
        self.infoView:layoutIfNeeded()
    end
    ), viewStack:onEmpty())

    Keyboard.input():on_chat_toggle():addAction(function(_, isChatOpen)
        if self.isChatOpen == isChatOpen then
            return
        end
        self.isChatOpen = isChatOpen

        if isChatOpen then
            if self:isVisible() then
                for key in L{'up','down','left','right','enter','numpadenter'}:it() do
                    windower.send_command('unbind %s':format(key))
                end
            end
        else
            if self:isVisible() then
                for key in L{'up','down','left','right','enter','numpadenter'}:it() do
                    windower.send_command('bind %s block':format(key))
                end
            end
        end
    end)

    return self
end

function Menu:destroy()
    self.disposeBag:destroy()
end

function Menu:showMenu(menuItem)
    if self.menuItemStack:contains(menuItem) then
        while self.menuItemStack:length() > 0 and self.menuItemStack[self.menuItemStack:length()]:getUUID() ~= menuItem:getUUID() do
            self.menuItemStack:remove(self.menuItemStack:length())
        end
    else
        self.menuItemStack:append(menuItem)
    end

    if not self.menuView then
        self.menuView = MenuView.new(menuItem, self.contentViewStack, self.infoView, function(menuItem) self:showMenu(menuItem) end)
        self.menuView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.menuView:getDelegate():deselectAllItems()

            local textItem = self.menuView:getDataSource():itemAtIndexPath(indexPath):getTextItem()

            local currentView = self.contentViewStack:getCurrentView()
            if currentView and type(currentView.onSelectMenuItemAtIndexPath) == 'function' then
                currentView:onSelectMenuItemAtIndexPath(textItem, indexPath)
            end

            local childMenuItem = self.menuView:getItem():getChildMenuItem(textItem:getText())
            if childMenuItem then
                if not childMenuItem:isEnabled() then
                    addon_system_message("Unable to perform this action.")
                    return
                end
                if type(childMenuItem) == 'function' then
                    childMenuItem()
                    return
                end
                if childMenuItem:getAction() ~= nil then
                    childMenuItem:getAction()(self)
                    return
                end
                if childMenuItem:getButtonItems():length() > 0 then
                    self:showMenu(childMenuItem)
                else
                    local menuArgs = {}
                    local currentView = self.viewStack:getCurrentView()
                    if currentView then
                        menuArgs = currentView and type(currentView.getMenuArgs) == 'function' and currentView:getMenuArgs()
                    end
                    local contentView = childMenuItem:getContentView(menuArgs, self.infoView)
                    if contentView then
                        self.menuView.views:append(contentView)
                        self.contentViewStack:present(contentView)
                        if contentView:hasFocus() then
                            self.menuView:setHasFocus(false)
                        end
                    end
                end
            end
        end)
        self.menuView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            self:onMoveCursorToIndexPath(indexPath)
        end)
    else
        self.menuView:setItem(menuItem)
    end

    local cursorIndexPath = self.menuView:getDelegate():getCursorIndexPath()
    self:onMoveCursorToIndexPath(cursorIndexPath)

    if self.viewStack:isEmpty() then
        self.viewStack:present(self.menuView)
        self.menuView:requestFocus()
    end

    self:requestFocus()
end

function Menu:updateInfoView(menuItem, parentMenuItem)
    local parentTitleText = parentMenuItem:getTitleText() or ""
    local parentDescriptionText = parentMenuItem:getDescriptionText() or ""
    if menuItem and type(menuItem) ~= 'function' then
        local titleText = menuItem:getTitleText() or parentTitleText
        local descriptionText = menuItem:getDescriptionText() or parentDescriptionText
        self.infoView:setTitle(titleText)
        self.infoView:setDescription(descriptionText)
    else
        self.infoView:setTitle(parentTitleText)
        self.infoView:setDescription(parentDescriptionText)
    end
end

function Menu:onMoveCursorToIndexPath(cursorIndexPath)
    local textItem = self.menuView:getDataSource():itemAtIndexPath(cursorIndexPath):getTextItem()
    local childMenuItem = self.menuView:getItem():getChildMenuItem(textItem:getText())
    self:updateInfoView(childMenuItem, self.menuView:getItem())
end

function Menu:onKeyboardEvent(key, pressed, flags, blocked)
    if windower.ffxi.get_info().chat_open or blocked then
        return blocked
    end
    if pressed then
        -- left
        if key == 203 then
            local currentView = self.contentViewStack:getCurrentView()
            if currentView and currentView:shouldRequestFocus() then
                currentView:requestFocus()
            end
        -- right
        elseif key == 205 then
            local currentView = self.contentViewStack:getCurrentView()
            if currentView and currentView:hasFocus() then
                currentView:resignFocus()
            end
        elseif key == 1 then
            if self.menuItemStack:length() > 1 then
                self.menuItemStack:remove(self.menuItemStack:length())
                self.menuView:setItem(self.menuItemStack[self.menuItemStack:length()])
            else
                self.viewStack:dismiss()
                self.menuItemStack = L{}
                self.menuView = nil
                FocusManager.shared():resignAllFocus()
            end
        else
            local currentView = self.viewStack:getCurrentView()
            if currentView then
                currentView:onKeyboardEvent(key, pressed, flags, blocked)
            end
        end
    end
    return L{1,203,205}:contains(key)
end

function Menu:closeAll()
    local isMenuShown = self:isVisible()

    if self.menuView then
        self.menuView:destroy()
        self.menuView = nil
    end
    self.menuItemStack = L{}
    self.viewStack:dismissAll()

    if isMenuShown then
        FocusManager.shared():resignAllFocus()
    end
end

function Menu:isVisible()
    return not self.menuItemStack:empty()
end

---
-- Returns whether the view should resign focus if it currently has focus.
--
-- @treturn boolean If the view should resign focus.
function Menu:shouldResignFocus()
    return self.resignFocus
end

---
-- Resigns focus from the view.
--
function Menu:resignFocus()
    FocusManager.shared():resignFocus(self)
end

---
-- Request focus for the view.
--
-- @treturn boolean True if the view is focused.
function Menu:requestFocus()
    return FocusManager.shared():requestFocus(self)
end

---
-- Returns whether the view has focus.
--
-- @treturn boolean If the view has focus.
function Menu:hasFocus()
    return self.focused
end

---
-- Sets whether the view has focus.
--
-- @tparam boolean hasFocus Whether the view has focus.
--
function Menu:setHasFocus(hasFocus)
    self.focused = hasFocus

    local currentView = self.viewStack:getCurrentView()
    if currentView then
        currentView:setHasFocus(hasFocus)
    end
end

return Menu
