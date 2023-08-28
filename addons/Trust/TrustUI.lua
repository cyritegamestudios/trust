local texts = require('texts')

local settings = {}
settings.pos = {}
settings.pos.x = -278
settings.pos.y = 21
settings.padding = 2
settings.text = {}
settings.text.font = 'Arial'
settings.text.size = 14
settings.text.stroke = {}
settings.text.stroke.width = 2
settings.text.stroke.alpha = 150
settings.flags = {}
settings.flags.bold = true
settings.flags.right = true

local debug_settings = {}
debug_settings.pos = {}
debug_settings.pos.x = -278
debug_settings.pos.y = 81
debug_settings.padding = 2
debug_settings.text = {}
debug_settings.text.font = 'Arial'
debug_settings.text.size = 12
debug_settings.flags = {}
debug_settings.flags.bold = true
debug_settings.flags.right = true

local target_settings = {}
target_settings.pos = {}
target_settings.pos.x = -278
target_settings.pos.y = 51
target_settings.padding = 2
target_settings.text = {}
target_settings.text.font = 'Arial'
target_settings.text.size = 14
target_settings.text.red = 255
target_settings.text.green = 128
target_settings.text.blue = 128
target_settings.text.stroke = {}
target_settings.text.stroke.width = 2
target_settings.text.stroke.alpha = 150
target_settings.flags = {}
target_settings.flags.bold = true
target_settings.flags.right = true

local trust_hud = texts.new('Trust: ${enabled||%3s}', settings)
local trust_debug_hud = texts.new('${text||%8s}', debug_settings)
local trust_target_hud = texts.new('${text||%8s}', target_settings)

local TrustUI = {}
TrustUI.__index = TrustUI

function TrustUI.new()
    local self = setmetatable({
        action_events = {};
        is_enabled = false;
        debug_text = '';
        target_text = '';
    }, TrustUI)

    trust_hud:bg_alpha(0)
    trust_debug_hud:bg_alpha(175)
    trust_target_hud:bg_alpha(0)

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

    trust_target_hud.text = self.target_text
    trust_target_hud:visible(self.target_text:length() > 0)

    if trust_target_hud:visible() then
        trust_debug_hud:pos(-278, 81)
        trust_target_hud:pos(-278, 51)
    else
        trust_debug_hud:pos(-278, 51)
    end
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

function TrustUI:set_target_text(text)
    self.target_text = text

    self:render()
end

return TrustUI