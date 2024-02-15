local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local Frame = require('cylibs/ui/views/frame')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MenuView = require('cylibs/ui/menu/menu_view')
local ViewStack = require('cylibs/ui/views/view_stack')

local Menu =  {}
Menu.__index = Menu


function Menu.new(contentViewStack, viewStack, infoView)
    local self = setmetatable({}, Menu)

    self.buttonHeight = 16
    self.disposeBag = DisposeBag.new()
    self.menuItemStack = L{}

    self.contentViewStack = contentViewStack
    self.viewStack = viewStack
    self.infoView = infoView

    self.disposeBag:addAny(L{ self.viewStack })

    self.disposeBag:add(viewStack:onStackSizeChanged():addAction(function(stackSize)
        if stackSize > 0 then
            for key in L{'up','down','left','right','enter'}:it() do
                windower.send_command('bind %s block':format(key))
            end
            self.infoView:setVisible(true)
            self.infoView:layoutIfNeeded()
        end
    end), viewStack:onStackSizeChanged())

    self.disposeBag:add(viewStack:onEmpty():addAction(function(_)
        for key in L{'up','down','left','right','enter'}:it() do
            windower.send_command('unbind %s':format(key))
        end
        self.infoView:setVisible(false)
        self.infoView:layoutIfNeeded()
    end
    ), viewStack:onEmpty())

    self.disposeBag:add(viewStack:onKeyboardEvent():addAction(function(_, key, pressed, flags, blocked)
        -- escape
        if key == 1 then
            if not self.viewStack:hasFocus() then
                self.viewStack:focus()
            end
        -- left
        elseif key == 203 then
            if self.contentViewStack:getCurrentView() and self.contentViewStack:getCurrentView():shouldRequestFocus() then
                self.contentViewStack:focus()
            end
        -- right
        elseif key == 205 then
            self.viewStack:focus()
        end
        self:onKeyboardEvent(key, pressed, flags, blocked)
    end), viewStack:onKeyboardEvent())

    return self
end

function Menu:destroy()
    self.disposeBag:destroy()
end

function Menu:showMenu(menuItem)
    self.menuItemStack:append(menuItem)

    if not self.menuView then
        self.menuView = MenuView.new(menuItem, self.contentViewStack)
        self.menuView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.menuView:getDelegate():deselectAllItems()
            local textItem = self.menuView:getDataSource():itemAtIndexPath(indexPath):getTextItem()
            local currentView = self.contentViewStack:getCurrentView()
            if currentView and type(currentView.onSelectMenuItemAtIndexPath) == 'function' then
                currentView:onSelectMenuItemAtIndexPath(textItem, indexPath)
            end

            local childMenuItem = self.menuView:getItem():getChildMenuItem(textItem:getText())
            if childMenuItem then
                if type(childMenuItem) == 'function' then
                    childMenuItem()
                    return
                end
                if childMenuItem:getAction() ~= nil then
                    childMenuItem:getAction()()
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
                    local contentView = childMenuItem:getContentView(menuArgs)
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
    end

    self.viewStack:focus()
end

function Menu:updateInfoView(menuItem)
    if menuItem and type(menuItem) ~= 'function' then
        self.infoView:setTitle(menuItem:getTitleText())
        self.infoView:setDescription(menuItem:getDescriptionText())
    else
        self.infoView:setTitle("")
        self.infoView:setDescription("")
    end
end

function Menu:onMoveCursorToIndexPath(cursorIndexPath)
    local textItem = self.menuView:getDataSource():itemAtIndexPath(cursorIndexPath):getTextItem()
    local childMenuItem = self.menuView:getItem():getChildMenuItem(textItem:getText())
    self:updateInfoView(childMenuItem)
end

function Menu:onKeyboardEvent(key, pressed, flags, blocked)
    if blocked then
        return blocked
    end
    if pressed then
        if key == 1 then
            if self.menuItemStack:length() > 1 then
                self.menuItemStack:remove(self.menuItemStack:length())
                self.menuView:setItem(self.menuItemStack[self.menuItemStack:length()])
            else
                self.viewStack:dismiss()
                self.menuItemStack = L{}
                self.menuView = nil
            end
        end
    end
    return L{1}:contains(key)
end

function Menu:closeAll()
    if self.menuView then
        self.menuView:destroy()
        self.menuView = nil
    end
    self.menuItemStack = L{}
    self.viewStack:dismissAll()
end

return Menu
