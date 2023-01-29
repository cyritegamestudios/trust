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

local debug_settings = {}
debug_settings.pos = {}
debug_settings.pos.x = -278
debug_settings.pos.y = 51
debug_settings.text = {}
debug_settings.text.font = 'Arial'
debug_settings.text.size = 14
debug_settings.flags = {}
debug_settings.flags.right = true

local trust_hud = texts.new('Trust: ${enabled||%8s}', settings)
local trust_debug_hud = texts.new('${text||%8s}', debug_settings)

local TrustUI = {}
TrustUI.__index = TrustUI

function TrustUI.new()
    local self = setmetatable({
        action_events = {};
        is_enabled = false;
        debug_text = '';
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

    trust_debug_hud.text = self.debug_text
    trust_debug_hud:visible(self.debug_text:length() > 0)
end

function TrustUI:set_enabled(is_enabled)
    if is_enabled == self.is_enabled then
        return
    end
    self.is_enabled = is_enabled

    self:render()
end

function TrustUI:set_debug_text(text)
    self.debug_text = text

    self:render()
end

return TrustUI