local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local ModesMenuItem = setmetatable({}, {__index = MenuItem })
ModesMenuItem.__index = ModesMenuItem
ModesMenuItem.__type = "ModesMenuItem"

function ModesMenuItem.new(trustModeSettings, description, modeNames, showModeName, shortcutConfigKey)
    description = description or "View and change Trust modes."

    modeNames = modeNames or L(T(state):keyset()):sort()
    modeNames = modeNames:filter(function(modeName)
        return state[modeName] ~= nil
    end)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Save', 18),
        ButtonItem.localized('Info', i18n.translate('Button_Info')),
    }, {},
        nil, "Modes", description), ModesMenuItem)

    self.trustModeSettings = trustModeSettings
    self.shortcutConfigKey = shortcutConfigKey
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local modesView = ModesView.new(modeNames, infoView, state, showModeName)
        modesView:setShouldRequestFocus(true)
        modesView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
            self.selectedModeName = modeNames[cursorIndexPath.section]
        end)
        self.selectedModeName = modeNames[1]
        return modesView
    end

    self:reloadSettings()

    return self
end

function ModesMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function ModesMenuItem:reloadSettings()
    self:setChildMenuItem("Confirm", MenuItem.action(function()
        addon_system_message("Modes will reload from the profile when the addon reloads. To update your profile, use Save instead.")
    end, "Modes", "Changes modes only until the addon reloads."))
    if self.trustModeSettings then
        self:setChildMenuItem("Save", MenuItem.action(function()
            if self.trustModeSettings then
                self.trustModeSettings:saveSettings(state.TrustMode.value)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll update my profile and remember this for next time!")
            else
                addon_system_error("Unable to save mode changes to profile. Please report this issue.")
            end
        end, "Modes", "Change modes and save changes to the current profile."))
    end
    self:setChildMenuItem("Info", self:getInfoMenuItem())
end

function ModesMenuItem:getInfoMenuItem()
    local infoButton = ButtonItem.localized('Info', i18n.translate('Button_Info'))
    infoButton:setEnabled(false)
    
    local infoMenuItem = MenuItem.new(L{
        infoButton
    }, {}, function(_, infoView)
        local modeSettings = {}
        local configItems = L{}
        for modeValue in L(state[self.selectedModeName]:options()):it() do
            local description = state[self.selectedModeName]:get_description(modeValue)
            if not description then
                description = "No description available."
            end
            description = description:gsub("^Okay, ", "")

            modeSettings[modeValue] = description
            configItems:append(PickerConfigItem.new(modeValue, description, L{ description }))
        end
        local commandConfigEditor = ConfigEditor.new(nil, modeSettings, configItems)
        commandConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
            local configItem = configItems[cursorIndexPath.section]
            infoView:setDescription(configItem:getInitialValue())
        end)
        return commandConfigEditor
    end, "Modes", "View details about the selected mode.", false, function()
        return self.selectedModeName ~= nil
    end)
    return infoMenuItem
end

function ModesMenuItem:getConfigKey()
    return self.shortcutConfigKey
end

return ModesMenuItem