local AttachmentSettingsMenuItem = require('ui/settings/menus/attachments/AttachmentSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ManeuverSettingsMenuItem = require('ui/settings/menus/attachments/ManeuverSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local AutomatonSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AutomatonSettingsMenuItem.__index = AutomatonSettingsMenuItem

function AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Attachments', 18),
        ButtonItem.default('Maneuvers', 18),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
    }, {}, nil, "Automaton", "Configure automaton settings."), AutomatonSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings

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
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for automaton behavior.",
            L{'AutoPetMode', 'AutoAssaultMode', 'AutoRepairMode', 'AutoManeuverMode'})
end

return AutomatonSettingsMenuItem