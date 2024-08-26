local AttachmentSettingsMenuItem = require('ui/settings/menus/attachments/AttachmentSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ManeuverSettingsMenuItem = require('ui/settings/menus/attachments/ManeuverSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')

local AutomatonSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AutomatonSettingsMenuItem.__index = AutomatonSettingsMenuItem

function AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Attachments', 18),
        ButtonItem.default('Maneuvers', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Automaton", "Configure automaton settings."), AutomatonSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode

    self:reloadSettings()

    return self
end

function AutomatonSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function AutomatonSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Attachments", self:getAttachmentSettingsMenuItem())
    self:setChildMenuItem("Maneuvers", self:getManeuverSettingsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function AutomatonSettingsMenuItem:getAttachmentSettingsMenuItem()
    local attachmentSettingsMenuItem = MenuItem.new(L{
        ButtonItem.default('Default'),
        ButtonItem.default('Overdrive'),
        ButtonItem.default('Custom'),
    }, {
        Default = AttachmentSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'Default', false),
        Overdrive = AttachmentSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'Overdrive', false),
        Custom = AttachmentSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'Custom', true),
    }, nil, "Attachments", "Equip or save attachment sets.")
    return attachmentSettingsMenuItem
end

function AutomatonSettingsMenuItem:getManeuverSettingsMenuItem()
    local maneuverSettingsMenuItem = MenuItem.new(L{
        ButtonItem.default('Default'),
        ButtonItem.default('Overdrive'),
    }, {
        Default = ManeuverSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'Default', "Edit Default maneuver sets. These will automatically be chosen based on equipped head/frame."),
        Overdrive = ManeuverSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'Overdrive', "Edit Default maneuver sets. These will automatically be chosen based on equipped head/frame while Overdrive is active."),
    }, nil, "Maneuvers", "Edit maneuver sets.")
    return maneuverSettingsMenuItem
end

function AutomatonSettingsMenuItem:getModesMenuItem()
    local automatonModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoPetMode', 'AutoAssaultMode', 'AutoRepairMode', 'AutoManeuverMode', 'ManeuverMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change automaton behavior.")
    return automatonModesMenuItem
end

return AutomatonSettingsMenuItem