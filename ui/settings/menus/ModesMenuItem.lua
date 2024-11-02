local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')

local ModesMenuItem = setmetatable({}, {__index = MenuItem })
ModesMenuItem.__index = ModesMenuItem
ModesMenuItem.__type = "ModesMenuItem"

function ModesMenuItem.new(trustModeSettings, description, modeNames, showModeName, shortcutConfigKey)
    description = description or "View and change Trust modes."
    modeNames = modeNames or L(T(state):keyset()):sort()
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Save', 18),
    }, {},
        function(_, infoView)
            local modesView = ModesView.new(modeNames, infoView, state, showModeName)
            modesView:setShouldRequestFocus(true)
            return modesView
        end, "Modes", description), ModesMenuItem)

    self.trustModeSettings = trustModeSettings
    self.shortcutConfigKey = shortcutConfigKey
    self.disposeBag = DisposeBag.new()

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
end

function ModesMenuItem:getConfigKey()
    return self.shortcutConfigKey
end

return ModesMenuItem