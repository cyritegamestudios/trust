local Event = require('cylibs/events/Luvent')
local Mouse = require('cylibs/ui/input/mouse')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local TooltipView = setmetatable({}, {__index = TextCollectionViewCell })
TooltipView.__index = TooltipView
TooltipView.__type = "TooltipView"

function TooltipView:onHoverOff()
    return self.hoverOff
end

function TooltipView.new(text, width, height, parentView)
    local self = setmetatable(TextCollectionViewCell.new(TextItem.new(text, TextStyle.Default.TextSmall)))

    self.hoverOff = Event.newEvent()

    self:getDisposeBag():add(Mouse.input():onMove():addAction(function(_, x, y, _, blocked)
        if blocked or not self:isVisible() then
            return false
        end

        if parentView:isDestroyed() or not parentView:hitTest(x, y) then
            self:onHoverOff():trigger(self, x, y)
        end
        return false
    end), Mouse.input():onMove())

    parentView:addSubview(self)

    self:setPosition(parentView.frame.x, parentView.frame.y + parentView.frame.height)

    self:setSize(width, height)
    self:setColor(150, 0, 0, 0)
    self:setVisible(true)

    return self
end

-- Destroys the Button, cleaning up any resources.
function TooltipView:destroy()
    TextCollectionViewCell.destroy(self)
    self:onHoverOff():removeAllActions()
end

function TooltipView:hitTest(x, y)
    return false
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function TooltipView:getText()
    return self.text
end

return TooltipView