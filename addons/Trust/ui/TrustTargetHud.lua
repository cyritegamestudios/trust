local texts = require('texts')
local Event = require('cylibs/events/Luvent')

local settings = {}
settings.pos = {}
settings.pos.x = -278
settings.pos.y = 51
settings.padding = 2
settings.text = {}
settings.text.font = 'Arial'
settings.text.size = 14
settings.text.red = 255
settings.text.green = 128
settings.text.blue = 128
settings.text.stroke = {}
settings.text.stroke.width = 2
settings.text.stroke.alpha = 150
settings.flags = {}
settings.flags.bold = true
settings.flags.right = true

local TrustTargetHud = {}
TrustTargetHud.__index = TrustTargetHud

-- Event called when the hud is re-rendered.
function TrustTargetHud:on_render()
    return self.rendered
end

function TrustTargetHud.new(party)
    local self = setmetatable({
        action_events = {};
        view = texts.new('${text||%8s}', settings);
        text = '';
        rendered = Event.newEvent();
    }, TrustTargetHud)

    self.view:bg_alpha(0)

    party:on_party_target_change():addAction(function(_, target_index)
        if target_index == nil then
            self:set_text('')
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            self:set_text(target.name)
        end
    end)

    self:render()

    return self
end

function TrustTargetHud:destroy()
    self:on_render():removeAllActions()
end

function TrustTargetHud:render()
    self.view.text = self:get_text()
    self.view:visible(self:get_text():length() > 0)

    self:on_render():trigger(self)
end

-------
-- Sets the text to be displayed.
-- @tparam string text Text
function TrustTargetHud:set_text(text)
    self.text = text

    self:render()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function TrustTargetHud:get_text()
    return self.text
end

-------
-- Returns the underlying view.
-- @treturn texts The view
function TrustTargetHud:get_view()
    return self.view
end

return TrustTargetHud