local texts = require('texts')
local TrustTargetHud = require('ui/TrustTargetHud')
local TrustActionHud = require('ui/TrustActionHud')
local TrustDetailsView = require('ui/TrustDetailsView')

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
settings.flags.draggable = false

local expand_button_settings = {}
expand_button_settings.pos = {}
expand_button_settings.pos.x = -250
expand_button_settings.pos.y = 21
expand_button_settings.padding = 2
expand_button_settings.text = {}
expand_button_settings.text.font = 'Arial'
expand_button_settings.text.size = 14
expand_button_settings.text.stroke = {}
expand_button_settings.text.stroke.width = 2
expand_button_settings.text.stroke.alpha = 150
expand_button_settings.flags = {}
expand_button_settings.flags.bold = true
expand_button_settings.flags.right = false
expand_button_settings.flags.draggable = false

local trust_hud = texts.new('Trust: ${enabled||%3s}', settings)

local TrustUI = {}
TrustUI.__index = TrustUI

function TrustUI.new(player, action_queue)
    local self = setmetatable({
        action_events = {};
        is_enabled = false;
        is_expanded = false;
        target_hud = TrustTargetHud.new(player.party);
        action_hud = TrustActionHud.new(action_queue);
        details_view = TrustDetailsView.new(player.trust.main_job);
        expand_button = texts.new('${icon||%3s}', expand_button_settings);
    }, TrustUI)

    -- Handle drag and drop
    self.action_events.mouse = windower.register_event('mouse', function(type, x, y, delta, blocked)
        if blocked then
            return
        end

        -- Mouse left click
        if type == 1 then
            if self.expand_button:hover(x, y) then
                self:set_expanded(not self.is_expanded)
            end
        end
        return false
    end)

    self.views = L{self.target_hud, self.action_hud, self.details_view}

    for view in self.views:it() do
        view:on_render():addAction(function(_)
            self:render()
        end)
    end

    trust_hud:bg_alpha(0)
    self.expand_button:bg_alpha(0)

    self:render()

    self:set_expanded(false)

    return self
end

function TrustUI:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    for view in self.views:it() do
        view:destroy()
    end
end

function TrustUI:render()
    if self.is_enabled then
        trust_hud.enabled = 'ON'
    else
        trust_hud.enabled = 'OFF'
    end
    trust_hud:visible(true)

    local pos_x, pos_y = windower.text.get_location(trust_hud._name)
    self.expand_button:pos(pos_x, pos_y)

    if self.target_hud:get_view():visible() then
        self.action_hud:get_view():pos(-278, 81)
        self.target_hud:get_view():pos(-278, 51)
    else
        self.action_hud:get_view():pos(-278, 51)
    end
end

function TrustUI:set_enabled(is_enabled)
    if is_enabled == self.is_enabled then
        return
    end
    self.is_enabled = is_enabled

    self:render()
end

function TrustUI:set_expanded(expanded)
    self.is_expanded = expanded
    if expanded then
        self.expand_button.icon = "▲"
        self.expand_button:visible(true)
        self.details_view:set_visible(true)
    else
        self.expand_button.icon = "▼"
        self.expand_button:visible(true)
        self.details_view:set_visible(false)
    end
    self:render()
end

return TrustUI