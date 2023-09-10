local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local TooltipView = setmetatable({}, {__index = TextListItemView })
TooltipView.__index = TooltipView


function TooltipView:onHoverOff()
    return self.hoverOff
end

function TooltipView.new(text, width, height, parentView)
    local self = setmetatable(TextListItemView.new(ListItem.new({ text = text, width = width, height = height }, ListViewItemStyle.DarkMode.TextSmall, 'tooltip_'..text, TooltipView.new)), TooltipView)

    self.hoverOff = Event.newEvent()

    self.disposeBag = DisposeBag.new()
    self.disposeBag:add(input:onMove():addAction(function(_, x, y, _, blocked)
        if blocked or not self:is_visible() then
            return false
        end

        if parentView:is_destroyed() or not parentView:hover(x, y) then
            self:onHoverOff():trigger(self, x, y)
        end
        return false
    end), input:onMove())

    local x, y = parentView:get_pos()
    local _, parentHeight = parentView:get_size()
    self:set_pos(x, y + parentHeight)

    self:set_size(width, height)
    self:set_color(150, 0, 0, 0)
    self:set_visible(true)

    return self
end

-- Destroys the Button, cleaning up any resources.
function TooltipView:destroy()
    TextListItemView.destroy(self)

    self.disposeBag:destroy()

    self:onHoverOff():removeAllActions()
end

function TooltipView:hover(x, y)
    return false
end

function TooltipView:render()
    TextListItemView.render(self)

    --[[local x, y = self:get_pos()
    local width, height = self:get_size()
    local textWidth, textHeight = self.textView:extents()

    self.textView:pos(x + (width - textWidth) / 2, y + (height - textHeight) / 2)]]
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function TooltipView:getText()
    return self.text
end

return TooltipView