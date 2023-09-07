local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local Button = setmetatable({}, {__index = TextListItemView })
Button.__index = Button

-- Event called when the button is clicked.
function Button:onClick()
    return self.click
end

-- Creates a new Button instance.
-- @tparam string text The text to display on the button.
-- @tparam number width The width of the button.
-- @tparam number height The height of the button.
-- @treturn Button The newly created Button instance.
function Button.new(text, width, height)
    local self = setmetatable(TextListItemView.new(ListItem.new({ text = text, width = width, height = height, highlightable = true }, ListViewItemStyle.DarkMode.Button, 'button_'..text, Button.new)), Button)

    self.click = Event.newEvent()

    self.disposeBag = DisposeBag.new()

    self.disposeBag:add(input:onClick():addAction(function(type, x, y, delta, blocked)
        if blocked then
            return
        end
        if type == 1 then
            if self:hover(x, y) then
                self:onClick():trigger(self, x, y)
                return false
            end
        end
        return false
    end), input:onClick())

    self.disposeBag:add(input:onMove():addAction(function(_, x, y, delta, blocked)
        if blocked or not self:is_visible() then
            return false
        end

        if self:hover(x, y) then
            self:set_highlighted(true)
        else
            self:set_highlighted(false)
        end

        return false
    end), input:onMove())

    return self
end

-- Destroys the Button, cleaning up any resources.
function Button:destroy()
    TextListItemView.destroy(self)

    self.disposeBag:destroy()

    self:onClick():removeAllActions()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function Button:getText()
    return self.text
end

return Button