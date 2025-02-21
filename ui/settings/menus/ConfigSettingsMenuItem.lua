local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local RemoteCommandsSettingsMenuItem = require('ui/settings/menus/RemoteCommandsSettingsMenuItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local ConfigSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConfigSettingsMenuItem.__index = ConfigSettingsMenuItem

function ConfigSettingsMenuItem.new(addonSettings, trustSettings, trustSettingsMode, mediaPlayer)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Widgets', 18),
        ButtonItem.default('GearSwap', 18),
        ButtonItem.default('Remote', 18),
        ButtonItem.default('Sounds', 18),
        ButtonItem.default('Language', 18),
        ButtonItem.default('Logging', 18),
    }, {}, nil, "Config", "Configure addon settings."), ConfigSettingsMenuItem)

    self.disposeBag = DisposeBag.new()
    self.mediaPlayer = mediaPlayer

    self:reloadSettings(addonSettings, trustSettings, trustSettingsMode)

    return self
end

function ConfigSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function ConfigSettingsMenuItem:reloadSettings(addonSettings, trustSettings, trustSettingsMode)
    self:setChildMenuItem("Widgets", WidgetSettingsMenuItem.new())
    self:setChildMenuItem("GearSwap", self:getGearSwapMenuItem(trustSettings, trustSettingsMode))
    self:setChildMenuItem("Logging", self:getLoggingMenuItem(addonSettings))
    self:setChildMenuItem("Remote", RemoteCommandsSettingsMenuItem.new(addonSettings))
    self:setChildMenuItem("Sounds", self:getSoundSettingsMenuItem(addonSettings))
    self:setChildMenuItem("Language", self:getLanguageSettingsMenuItem(addonSettings))
end

function ConfigSettingsMenuItem:getGearSwapMenuItem(trustSettings, trustSettingsMode)
    local gearSwapMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
    }, {}, function(_, infoView)
        local gearSwapSettings = trustSettings:getSettings()[trustSettingsMode.value].GearSwapSettings
        gearSwapSettings.Language = gearSwapSettings.Language or i18n.Locale.English
        local configItems = L{
            BooleanConfigItem.new('Enabled', "Is GearSwap Enabled"),
            PickerConfigItem.new('Language', i18n.current_gearswap_locale(), L{ i18n.Locale.English, i18n.Locale.Japanese }, function(locale)
                if locale == i18n.Locale.Japanese then
                    return 'Japanese'
                else
                    return 'English'
                end
            end),
        }
        local gearSwapSettingsEditor = ConfigEditor.new(trustSettings, gearSwapSettings, configItems, infoView)

        self.disposeBag:add(gearSwapSettingsEditor:onConfigChanged():addAction(function(newConfigSettings, _)
            i18n.set_current_gearswap_locale(newConfigSettings.Language)
        end), gearSwapSettingsEditor:onConfigChanged())

        return gearSwapSettingsEditor
    end, "GearSwap", "Configure GearSwap integration with Trust.")
    return gearSwapMenuItem
end

function ConfigSettingsMenuItem:getLoggingMenuItem(addonSettings)
    local loggingMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
        ButtonItem.localized('Clear', i18n.translate('Button_Clear')),
    }, {}, function(_, infoView)
        local loggingSettings = addonSettings:getSettings()[("logging"):lower()]

        local configItems = L{
            BooleanConfigItem.new('enabled', "Enable Logging"),
            BooleanConfigItem.new('logtofile', "Log to File"),
            TextInputConfigItem.new('filter_pattern', loggingSettings.filter_pattern, "Filter Pattern"),
        }
        local loggingSettingsEditor = ConfigEditor.new(addonSettings, addonSettings:getSettings()[("logging"):lower()], configItems, infoView)

        self.disposeBag:add(loggingSettingsEditor:onConfigChanged():addAction(function(newSettings)
            logger.isEnabled = addonSettings:getSettings().logging.enabled
            logger.set_filter(newSettings.filter_pattern)

            _libs.logger.settings.logtofile = addonSettings:getSettings().logging.logtofile
        end), loggingSettingsEditor:onConfigChanged())

        return loggingSettingsEditor
    end, "Logging", "Configure debug logging.")

    loggingMenuItem:setChildMenuItem("Clear", MenuItem.action(function(menu)
        logger.set_filter('')
        addonSettings:getSettings().logging.filter_pattern = ''
        addonSettings:saveSettings(true)
        menu:showMenu(loggingMenuItem)
    end, "Logging", "Clear debug logging filters."))

    return loggingMenuItem
end

function ConfigSettingsMenuItem:getSoundSettingsMenuItem(addonSettings)
    local languageMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
    }, {
        Save = MenuItem.action(function()
            self.mediaPlayer:setEnabled(not addonSettings:getSettings().sounds.sound_effects.disabled)
        end),
    }, function(menuArgs)
        local configItems = L{
            BooleanConfigItem.new('disabled', "Disable sound effects"),
        }
        return ConfigEditor.new(addonSettings, addonSettings:getSettings().sounds.sound_effects, configItems)
    end, "Sounds", "Configure sound settings.")
    return languageMenuItem
end

function ConfigSettingsMenuItem:getLanguageSettingsMenuItem(addonSettings)
    local languageMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
        ButtonItem.default('Reset'),
    }, {
        Reset = MenuItem.action(function(parent)
            addonSettings:getSettings().locales.default = ""
            addonSettings:saveSettings(true)

            i18n.set_current_locale(i18n.Locale.Default)

            parent:showMenu(self)
        end),
    }, function(menuArgs)
        local languageSettings = {
            Language = i18n.current_locale(),
        }
        local configItems = L{
            PickerConfigItem.new('Language', i18n.current_locale(), L{ i18n.Locale.English, i18n.Locale.Japanese }, function(locale)
                if locale == i18n.Locale.Japanese then
                    return 'Japanese'
                else
                    return 'English'
                end
            end),
        }
        local languageConfigEditor = ConfigEditor.new(addonSettings, languageSettings, configItems)

        self.disposeBag:add(languageConfigEditor:onConfigChanged():addAction(function(newConfigSettings, _)
            addonSettings:getSettings().locales.default = newConfigSettings.Language
            i18n.set_current_locale(newConfigSettings.Language)
        end), languageConfigEditor:onConfigChanged())

        return languageConfigEditor
    end, "Language", "Configure language settings.")
    return languageMenuItem
end

return ConfigSettingsMenuItem