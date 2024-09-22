local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModeConfigEditor = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TrustModeSettings = require('TrustModeSettings')

local PartyMemberMenuItem = setmetatable({}, {__index = MenuItem })
PartyMemberMenuItem.__index = PartyMemberMenuItem

function PartyMemberMenuItem.new(partyMember)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, partyMember:get_name(), "See status and configure party member."), PartyMemberMenuItem)

    self.trustMode = M{['description'] = partyMember:get_name()..' Trust Mode', T{}}
    self.partyMember = partyMember

    self.trustModeSettings = TrustModeSettings.new(partyMember:get_main_job_short(), partyMember:get_name(), self.trustMode)
    self.trustModeSettings:loadSettings()
    self.modes = T(self.trustModeSettings:getSettings()).Default
    self.modeNames = self.modes:keyset()

    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function PartyMemberMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function PartyMemberMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function PartyMemberMenuItem:getModesMenuItem()
    local partyMemberModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModeConfigEditor.new(L(self.modeNames), infoView, self.modes)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Set modes for "..self.partyMember:get_name())
    return partyMemberModesMenuItem
end

return PartyMemberMenuItem