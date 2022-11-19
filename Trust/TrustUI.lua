local texts = require('texts')

local settings = {}
settings.pos = {}
settings.pos.x = -278
settings.pos.y = 21
settings.text = {}
settings.text.font = 'Arial'
settings.text.size = 14
settings.flags = {}
settings.flags.right = true

local trust_hud = texts.new('Trust: ${enabled||%8s}', settings)

local TrustUI = {}
TrustUI.__index = TrustUI

function TrustUI.new()
    local self = setmetatable({
        action_events = {};
        is_enabled = false;
    }, TrustUI)

    self:render()

    return self
end

function TrustUI:destroy()
end

function TrustUI:render()
    if self.is_enabled then
        trust_hud.enabled = 'ON'
    else
        trust_hud.enabled = 'OFF'
    end
    trust_hud:visible(true)
end

function TrustUI:set_enabled(is_enabled)
    if is_enabled == self.is_enabled then
        return
    end
    self.is_enabled = is_enabled

    self:render()
end

return TrustUI