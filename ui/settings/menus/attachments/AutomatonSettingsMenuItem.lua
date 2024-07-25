local AttachmentSettingsMenuItem = require('ui/settings/menus/attachments/AttachmentSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')

local AutomatonSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AutomatonSettingsMenuItem.__index = AutomatonSettingsMenuItem

function AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Attachments', 18),
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
    self:setChildMenuItem("Attachments", AttachmentSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function AutomatonSettingsMenuItem:getModesMenuItem()
    local automatonModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoAssaultMode', 'AutoManeuverMode', 'AutoPetMode', 'AutoRepairMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change automaton behavior.")
    return automatonModesMenuItem
end

return AutomatonSettingsMenuItem