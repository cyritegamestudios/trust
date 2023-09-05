local ListItemView = require('cylibs/ui/list_item_view')
local texts = require('texts')

local TextListItemView = setmetatable({}, {__index = ListItemView })
TextListItemView.__index = TextListItemView

---
-- Creates a new TextListItemView instance.
--
-- @tparam ListViewItem item The item to display in the view.
-- @treturn TextListItemView The newly created TextListItemView instance.
--
function TextListItemView.new(item)
    local self = setmetatable(ListItemView.new(item), TextListItemView)

    local settings = {}

    settings.pos = {}
    settings.padding = item.style:getPadding()
    settings.text = {}
    settings.text.alpha = 255
    settings.text.red = item.style:getFontColor().red
    settings.text.green = item.style:getFontColor().green
    settings.text.blue = item.style:getFontColor().blue
    settings.text.font = item.style:getFontName()
    settings.text.size = item.style:getFontSize()
    settings.text.stroke = {}
    settings.text.stroke.width = item.style:getStrokeWidth()
    settings.text.stroke.alpha = item.style:getStrokeAlpha()
    settings.flags = {}
    settings.flags.bold = item.style:isBold()
    settings.flags.right = false
    settings.flags.draggable = false

    self.textView = texts.new(item.data.pattern or '${text}', settings);

    local width = item.data.width or 40
    local height = item.data.height or 40

    self:set_size(width, height)

    local backgroundColor = item.style:getDefaultBackgroundColor()
    self:set_color(backgroundColor.alpha, backgroundColor.red, backgroundColor.green, backgroundColor.blue)

    self:set_selectable(item.data.selectable or false)
    self:set_highlightable(item.data.highlightable or false)

    return self
end

function TextListItemView:destroy()
    ListItemView.destroy(self)

    self.textView:destroy()
end

function TextListItemView:render()
    self.textView.text = self:getItem().data.text or ''

    local x, y = self:get_pos()

    self.textView:bg_alpha(0)
    self.textView:pos(x, y)
    self.textView:visible(self:is_visible())

    if self:is_selectable() and self:is_visible() then
        if self:is_selected() then
            self.textView:alpha(255)
        else
            self.textView:alpha(175)
        end
    end
end

function TextListItemView:set_highlighted(highlighted)
    ListItemView.set_highlighted(self, highlighted)

    local style = self:getItem():getStyle()
    if highlighted then
        self:setTextColor(style:getHighlightColor().red, style:getHighlightColor().green, style:getHighlightColor().blue)
    else
        self:setTextColor(style:getFontColor().red, style:getFontColor().green, style:getFontColor().blue)
    end
end

function TextListItemView:setTextColor(red, green, blue)
    self.textView:color(red, green, blue)
end

function TextListItemView:hover(x, y)
    if not self:is_visible() then
        return false
    end

    local xPos, yPos = self:get_pos()
    local width, height = self:get_size()
    -- FIXME: (scretella) why is this needed?
    yPos = yPos - 20
    local buffer = 0

    if x >= xPos - buffer and x <= xPos + width + buffer and y >= yPos - buffer and y <= yPos + height + buffer then
        return true
    end
    return false
end

return TextListItemView