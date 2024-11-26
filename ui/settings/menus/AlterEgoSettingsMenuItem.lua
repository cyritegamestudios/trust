local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local AlterEgoSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AlterEgoSettingsMenuItem.__index = AlterEgoSettingsMenuItem

function AlterEgoSettingsMenuItem.new(truster, trustModeSettings, addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Alter Egos", "Choose Alter Egos to call."), AlterEgoSettingsMenuItem)

    self.truster = truster
    self.trustModeSettings = trustModeSettings
    self.addonSettings = addonSettings
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local allSettings = L(addonSettings:getSettings().battle.trusts)

        local alterEgoSettings = T{}
        local configItems = L{}
        for i = 1, allSettings:length() do
            local allAlterEgos = res.spells:with_all('type', 'Trust'):map(function(alterEgo) return alterEgo.en end)
                :filter(function(alterEgo) return spell_util.knows_spell(spell_util.spell_id(alterEgo))  end)
                :sort()
            local alterEgoKey = "Trust"..i
            local alterEgoName = allSettings[i]
            alterEgoSettings[alterEgoKey] = alterEgoName
            configItems:append(PickerConfigItem.new(alterEgoKey, alterEgoName, allAlterEgos, function(alterEgoName)
                return i18n.resource('spells', 'en', alterEgoName)
            end, "Alter Ego "..i))
        end

        local alterEgoConfigEditor = ConfigEditor.new(addonSettings, alterEgoSettings, configItems, infoView, function(newSettings)
            local newAlterEgos = L{}
            for i = 1, allSettings:length() do
                local alterEgoKey = "Trust"..i
                newAlterEgos:append(newSettings[alterEgoKey])
            end
            return S(newAlterEgos):length() == allSettings:length()
        end)

        alterEgoConfigEditor:setTitle("Choose Alter Egos to call.")
        alterEgoConfigEditor:setShouldRequestFocus(true)

        self.disposeBag:add(alterEgoConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            local alterEgoNames = L{}

            for i = 1, newSettings:keyset():length() do
                local alterEgoKey = "Trust"..i
                local alterEgoName = newSettings[alterEgoKey]
                alterEgoNames:append(alterEgoName)
            end

            self.truster:set_trusts(alterEgoNames)

            self.addonSettings:getSettings().battle.trusts = alterEgoNames
            self.addonSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll call Alter Egos in this order!")
        end), alterEgoConfigEditor:onConfigChanged())

        self.disposeBag:add(alterEgoConfigEditor:onConfigValidationError():addAction(function(newSettings, _)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't summon the same Alter Ego twice!")
        end), alterEgoConfigEditor:onConfigValidationError())

        return alterEgoConfigEditor
    end

    self:reloadSettings()

    return self
end

function AlterEgoSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function AlterEgoSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function AlterEgoSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for calling alter egos to fight by your side.",
            L{'AutoTrustsMode'})
end

return AlterEgoSettingsMenuItem