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
settings.flags.right = true

local TrustActionHud = {}
TrustActionHud.__index = TrustActionHud

-- Event called when the hud is re-rendered.
function TrustActionHud:on_render()
    return self.rendered
end

function TrustActionHud.new(action_queue)
    local self = setmetatable({
        action_events = {};
        view = texts.new('${text||%8s}', settings);
        text = '';
        rendered = Event.newEvent();
    }, TrustActionHud)

    self.view:bg_alpha(175)

    action_queue:on_action_start():addAction(function(_, s)
        self:set_text(s or '')
    end)
    action_queue:on_action_end():addAction(function(_, s)
        self:set_text('')
    end)

    self:render()

    return self
end

function TrustActionHud:destroy()
    self:on_render():removeAllActions()
end

function TrustActionHud:render()
    self.view.text = self:get_text()
    self.view:visible(self:get_text():length() > 0)

    self:on_render():trigger(self)
end

-------
-- Sets the text to be displayed.
-- @tparam string text Text
function TrustActionHud:set_text(text)
    self.text = text

    self:render()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function TrustActionHud:get_text()
    return self.text
end

-------
-- Returns the underlying view.
-- @treturn texts The view
function TrustActionHud:get_view()
    return self.view
end

return TrustActionHud