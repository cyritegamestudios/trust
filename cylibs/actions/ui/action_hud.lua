local Event = require('cylibs/events/Luvent')
local Frame = require('cylibs/ui/views/frame')
local Renderer = require('cylibs/ui/views/render')
local texts = require('texts')
local TextStyle = require('cylibs/ui/style/text_style')

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

local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local ActionHud = setmetatable({}, {__index = NavigationBar })
ActionHud.__index = ActionHud

function ActionHud.new(actionQueue, hideBackground)
    local self = setmetatable(NavigationBar.new(Frame.new(0, 0, 175, 28), hideBackground, TextStyle.Default.ButtonSmall), ActionHud)

    self.actionQueue = actionQueue

    self:getDisposeBag():add(actionQueue:on_action_start():addAction(function(_, s)
        self:setTitle(s or '')
    end), actionQueue:on_action_start())
    self:getDisposeBag():add(actionQueue:on_action_end():addAction(function(_, s)
        self:setTitle('')
    end), actionQueue:on_action_end())

    self:setTitle('')

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(Renderer.shared():onPrerender():addAction(function()
        if self:isVisible() then
            local width, _ = self.textView:extents()
            self:setSize(math.max(100, width + 10), self:getSize().height)
            self:layoutIfNeeded()
        end
    end), Renderer.shared():onPrerender())

    return self
end

function ActionHud:setTitle(title)
    self:setVisible(not title:empty())

    NavigationBar.setTitle(self, title)
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function ActionHud:getText()
    return self:getItem():getText()
end

return ActionHud