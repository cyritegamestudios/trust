local Event = require('cylibs/events/Luvent')
local Mouse = require('cylibs/ui/input/mouse')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local Button = setmetatable({}, {__index = TextCollectionViewCell })
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
    local self = setmetatable(TextCollectionViewCell.new(TextItem.new(text, TextStyle.Default.Button)), Button)

    self:setSize(width, height)
    self:setUserInteractionEnabled(true)

    self.click = Event.newEvent()

    self:getDisposeBag():add(Mouse.input():onClick():addAction(function(type, x, y, delta, blocked)
        if blocked or not self:isVisible() then
            return
        end
        if self:hitTest(x, y) then
            self:setSelected(true)
        end
        return false
    end), Mouse.input():onClick())

    self:getDisposeBag():add(Mouse.input():onClickRelease():addAction(function(type, x, y, delta, blocked)
        if blocked or not self:isVisible() then
            return
        end
        self:setSelected(false)
        if self:hitTest(x, y) then
            self:onClick():trigger(self, x, y)
        end
        return false
    end), Mouse.input():onClickRelease())

    self:getDisposeBag():add(Mouse.input():onMove():addAction(function(_, x, y, delta, blocked)
        if blocked or not self:isVisible() then
            return false
        end
        if self:hitTest(x, y) then
            self:setHighlighted(true)
        else
            self:setHighlighted(false)
        end
        return false
    end), Mouse.input():onMove())

    self:layoutIfNeeded()

    return self
end

-- Destroys the Button, cleaning up any resources.
function Button:destroy()
    TextCollectionViewCell.destroy(self)

    self:onClick():removeAllActions()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function Button:getText()
    return self.text
end

return Button