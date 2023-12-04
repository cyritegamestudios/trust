local texts = require('texts')
local Event = require('cylibs/events/Luvent')

local settings = {}
settings.pos = {}
settings.pos.x = -278
settings.pos.y = 81
settings.padding = 2
settings.text = {}
settings.text.font = 'Arial'
settings.text.size = 12
settings.flags = {}
settings.flags.bold = true
settings.flags.right = false

local View = require('cylibs/ui/views/view')

local ActionHud = setmetatable({}, {__index = View })
ActionHud.__index = ActionHud

function ActionHud.new(actionQueue)
    local self = setmetatable(View.new(), ActionHud)

    self.actionQueue = actionQueue
    self.text = ''

    self.textView = texts.new('${text||%8s}', settings)
    self.textView:bg_alpha(175)

    self:getDisposeBag():add(actionQueue:on_action_start():addAction(function(_, s)
        self:setText(s or '')
    end), actionQueue:on_action_start())
    self:getDisposeBag():add(actionQueue:on_action_end():addAction(function(_, s)
        self:setText('')
    end), actionQueue:on_action_end())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ActionHud:destroy()
    View.destroy(self)

    self.textView:destroy()
end

function ActionHud:layoutIfNeeded()
    if not View.layoutIfNeeded(self) then
        return
    end

    self:setVisible(self:getText():length() > 0)

    local position = self:getAbsolutePosition()

    self.textView:visible(self:isVisible())
    self.textView:pos(position.x, position.y)
    self.textView.text = self:getText()
end

-------
-- Sets the text to be displayed.
-- @tparam string text Text
function ActionHud:setText(text)
    if self.text == text then
        return
    end
    self.text = text

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function ActionHud:getText()
    return self.text
end

return ActionHud