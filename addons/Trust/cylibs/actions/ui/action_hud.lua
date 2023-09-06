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

local View = require('cylibs/ui/view')

local ActionHud = setmetatable({}, {__index = View })
ActionHud.__index = ActionHud

function ActionHud.new(actionQueue)
    local self = setmetatable(View.new(), ActionHud)

    self.actionQueue = actionQueue
    self.text = ''

    self:set_color(0, 0, 0, 0)

    self.textView = texts.new('${text||%8s}', settings)
    self.textView:bg_alpha(175)

    self.actionStartId = actionQueue:on_action_start():addAction(function(_, s)
        self:setText(s or '')
    end)
    self.actionEndId = actionQueue:on_action_end():addAction(function(_, s)
        self:setText('')
    end)

    self:render()

    return self
end

function ActionHud:destroy()
    self:removeAllChildren()

    self.textView:destroy()

    self.actionQueue:on_action_start():removeAction(self.actionStartId)
    self.actionQueue:on_action_end():removeAction(self.actionEndId)
end

function ActionHud:render()
    View.render(self)

    self:set_visible(self:getText():length() > 0)

    local x, y = self:get_pos()

    self.textView:visible(self:is_visible())
    self.textView:pos(x, y)
    self.textView.text = self:getText()
end

-------
-- Sets the text to be displayed.
-- @tparam string text Text
function ActionHud:setText(text)
    self.text = text

    self:render()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function ActionHud:getText()
    return self.text
end

return ActionHud