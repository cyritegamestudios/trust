local texts = require('texts')
local Event = require('cylibs/events/Luvent')

local settings = {}
settings.pos = {}
settings.pos.x = -278
settings.pos.y = 121
settings.padding = 2
settings.text = {}
settings.text.font = 'Arial'
settings.text.size = 12
settings.text.stroke = {}
settings.text.stroke.width = 1
settings.text.stroke.alpha = 150
settings.flags = {}
settings.flags.bold = false
settings.flags.right = true

local TrustDetailsView = {}
TrustDetailsView.__index = TrustDetailsView

-- Event called when the view is re-rendered.
function TrustDetailsView:on_render()
    return self.rendered
end

function TrustDetailsView.new(trust, trust_job_name)
    local self = setmetatable({
        action_events = {};
        view = texts.new('${text||%8s}', settings);
        text = '';
        trust = trust;
        trust_job_name = trust_job_name;
        rendered = Event.newEvent();
    }, TrustDetailsView)

    self.view:bg_alpha(175)

    self:render()

    return self
end

function TrustDetailsView:destroy()
    self:on_render():removeAllActions()
end

function TrustDetailsView:render()
    self:on_render():trigger(self)
end

-------
-- Sets the text to be displayed.
-- @tparam string text Text
function TrustDetailsView:set_text(text)
    self.text = text

    self:render()
end

-------
-- Returns the text currently displayed.
-- @treturn string Text
function TrustDetailsView:get_text()
    return self.text
end

-------
-- Sets the visibility of the view.
-- @tparam boolean visible Visibility of the view
function TrustDetailsView:set_visible(visible)
    if visible then
        self:update_text()
    end
    self:get_view():visible(visible)

    self:render()
end

-------
-- Sets the visibility of the view.
-- @tparam Trust trust Trust to show information for
-- @tparam string trust_job_name Job name
function TrustDetailsView:set_trust(trust, trust_job_name)
    self.trust = trust
    self.trust_job_name = trust_job_name

    self:update_text()

    self:render()
end

-------
-- Returns the underlying view.
-- @treturn texts The view
function TrustDetailsView:get_view()
    return self.view
end

-------
-- Returns the trust job name.
-- @treturn string The trust job name
function TrustDetailsView:get_trust_job_name()
    return self.trust_job_name
end

-------
-- Updates the text.
function TrustDetailsView:update_text()
    local text = ""
    for role in self.trust:get_roles():it() do
        local role_details = role:tostring()
        if role_details then
            text = text..role_details..'\n'
        end
    end
    self:get_view().text = text
end

return TrustDetailsView