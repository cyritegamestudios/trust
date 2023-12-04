local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local Frame = require('cylibs/ui/views/frame')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MenuView = require('cylibs/ui/menu/menu_view')
local ViewStack = require('cylibs/ui/views/view_stack')

local Menu =  {}
Menu.__index = Menu


function Menu.new(contentViewStack, viewStack)
    local self = setmetatable({}, Menu)

    self.buttonHeight = 18
    self.disposeBag = DisposeBag.new()
    self.viewStack = viewStack
    self.contentViewStack = contentViewStack

    self.disposeBag:addAny(L{ self.viewStack })

    self.disposeBag:add(contentViewStack:onKeyboardEvent():addAction(function(_, key, pressed, flags, blocked)
        if pressed then
            if key ==  1 then
                if contentViewStack:getNumViews() > 0 then
                    contentViewStack:dismiss()
                end
            end
        end
    end), contentViewStack:onKeyboardEvent())

    self.disposeBag:add(contentViewStack:onViewDismissed():addAction(function(_, _)
        if not self.contentViewStack:isEmpty() and not self.contentViewStack:getCurrentView():shouldRequestFocus() then
            self.viewStack:focus()
        end
        self.viewStack:focus()
    end), contentViewStack:onViewDismissed())

    self.disposeBag:add(contentViewStack:onEmpty():addAction(function(_)
        self.viewStack:focus()
    end), contentViewStack:onEmpty())

    self.disposeBag:add(viewStack:onKeyboardEvent():addAction(function(_, key, pressed, flags, blocked)
        if pressed then
            if key ==  1 then
                if viewStack:getNumViews() > 0 then
                    if not contentViewStack:isEmpty() and not contentViewStack:getCurrentView():shouldRequestFocus() then
                        contentViewStack:dismiss()
                    end
                    --while not contentViewStack:isEmpty() and not contentViewStack:getCurrentView():shouldRequestFocus() do
                    --    contentViewStack:dismiss()
                    --end
                    viewStack:dismiss()
                end
            end
        end
    end), viewStack:onKeyboardEvent())

    self.disposeBag:add(viewStack:onStackSizeChanged():addAction(function(stackSize)
        if stackSize > 0 then
            for key in L{'up','down','enter'}:it() do
                windower.send_command('bind %s block':format(key))
            end
        end
    end), viewStack:onStackSizeChanged())

    self.disposeBag:add(viewStack:onEmpty():addAction(function(_)
        for key in L{'up','down','enter'}:it() do
            windower.send_command('unbind %s':format(key))
        end
    end
    ), viewStack:onEmpty())

    self.disposeBag:add(contentViewStack:onEmpty():addAction(function(_)
        viewStack:focus()
    end), contentViewStack:onEmpty())

    return self
end

function Menu:destroy()
    self.disposeBag:destroy()
end

function Menu:showMenu(menuItem)
    local menu = self:createMenu(menuItem)
    if menu then
        menu:onSelectMenuItemAtIndexPath():addAction(function(m, textItem, indexPath)
            local currentView = self.contentViewStack:getCurrentView()
            if currentView and type(currentView.onSelectMenuItemAtIndexPath) == 'function' then
                currentView:onSelectMenuItemAtIndexPath(textItem, indexPath)
            end
            local childMenuItem = m:getItem():getChildMenuItem(textItem:getText())
            if childMenuItem then
                local contentView = childMenuItem:getContentView(currentView and type(currentView.getMenuArgs) == 'function' and currentView:getMenuArgs())
                if contentView then
                    if contentView:shouldRequestFocus() then
                        self.contentViewStack:focus()
                    end
                    self.contentViewStack:present(contentView)
                end
                if childMenuItem:getButtonItems():length() > 0 then
                    self:showMenu(childMenuItem)
                end
            else
                --local currentView = self.contentViewStack:getCurrentView()
                --if currentView and type(currentView.onSelectMenuItemAtIndexPath) == 'function' then
                --    currentView:onSelectMenuItemAtIndexPath(textItem, indexPath)
                --end
            end
        end)
        self.viewStack:present(menu)
    end
end

function Menu:createMenu(menuItem)
    local menuView = MenuView.new(menuItem)

    menuView:setVisible(false)
    menuView:layoutIfNeeded()

    return menuView
end

function Menu:closeAll()
    self.viewStack:dismissAll()
end

return Menu
