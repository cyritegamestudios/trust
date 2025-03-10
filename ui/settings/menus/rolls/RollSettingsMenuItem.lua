local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local RollSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RollSettingsMenuItem.__index = RollSettingsMenuItem

function RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
    }, {
    }, nil, "Rolls", "Configure settings for Phantom Roll."), RollSettingsMenuItem)

    self.all_rolls = trust:get_job():get_all_rolls():sort()
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, _)
        local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

        local rollSettings = T{
            Roll1 = allSettings.Roll1:get_roll_name(),
            Roll2 = allSettings.Roll2:get_roll_name(),
        }

        local configItems = L{
            PickerConfigItem.new('Roll1', rollSettings.Roll1, trust:get_job():get_all_rolls():sort(), nil, "Roll 1 (Crooked Cards)"),
            PickerConfigItem.new('Roll2', rollSettings.Roll2, trust:get_job():get_all_rolls():sort(), nil, "Roll 2"),
        }

        local rollConfigEditor = ConfigEditor.new(self.trustSettings, rollSettings, configItems)

        rollConfigEditor:setTitle('Configure general song settings.')
        rollConfigEditor:setShouldRequestFocus(true)

        self.dispose_bag:add(rollConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            if newSettings.Roll1 ~= newSettings.Roll2 then
                allSettings.Roll1 = Roll.new(newSettings.Roll1, true)
                allSettings.Roll2 = Roll.new(newSettings.Roll2, false)

                self.trustSettings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..newSettings.Roll1.." and "..newSettings.Roll2.." now!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't use the same roll twice!")
            end
        end), rollConfigEditor:onConfigChanged())

        return rollConfigEditor
    end

    self:reloadSettings()

    self.dispose_bag:add(trustSettingsMode:on_state_change():addAction(function(_, newValue)
        self:reloadSettings()
    end, trustSettingsMode:on_state_change()))

    return self
end

function RollSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function RollSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function RollSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for rolls.", L{'AutoRollMode'})
end

return RollSettingsMenuItem