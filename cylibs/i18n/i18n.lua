---------------------------
-- Utility functions for i18n.
-- @class module
-- @name i18n

local Event = require('cylibs/events/Luvent')
local res = require('resources')

local i18n = {}

local locale = windower.ffxi.get_info().language
local locale_changed = Event.newEvent()

local translations = T{}
translations.Current = T{}
translations.English = T{}


i18n.Locale = {}
i18n.Locale.English = 'en'
i18n.Locale.Japanese = 'ja'

local fonts_for_locales = T{
    [i18n.Locale.English] = "Arial",
    [i18n.Locale.Japanese] = "MS Gothic",
}
local translations_for_locales = T{}

-------
-- Event called when the locale is changed.
-- @tparam Luvent Event
function i18n.onLocaleChanged()
    return locale_changed
end

function i18n.init(new_locale, translation_paths, font_map)
    locale = new_locale
    translations_for_locales = translation_paths
    fonts_for_locales = font_map

    translations[new_locale] = require(translation_paths[new_locale])
    if new_locale ~= i18n.Locale.English then
        translations[i18n.Locale.English] = require(translation_paths[i18n.Locale.English])
    else
        translations[i18n.Locale.English] = translations[new_locale]
    end
end

function i18n.current_locale()
    return locale
end

-------
-- Sets the current locale.
-- @tparam i18n.Locale locale Locale (e.g. 'en', 'jp')
function i18n.set_current_locale(new_locale)
    if new_locale == locale then
        return
    end
    locale = new_locale

    i18n.onLocaleChanged():trigger(new_locale)
end

-------
-- Sets the locale to be used when localization action commands (e.g. /ma <spell_name> <t>)
-- @tparam string locale Locale (e.g. 'en', 'jp')
function i18n.translate(key, args)
    local translation = translations[i18n.current_locale()][key]
    if translation then
        return translation.singular
    end
    return translations[i18n.Locale.English][key] and translations[i18n.Locale.English][key].singular or key
end

function i18n.resource(resource_name, key, value)
    if S{ 'en', 'ens' }:contains(key) and locale == i18n.Locale.English then
        return value
    end
    local item = res[resource_name]:with(key, value) or res[resource_name]:with(key, value:lower())
    if item then
        return item[locale]
    end
    return 'Unknown'
end

-------
-- Returns the font for the given locale.
-- @tparam i18n.Locale locale Locale (e.g. 'en', 'jp')
-- @treturn string Font name for the given locale
function i18n.font_for_locale(locale)
    local font_name = fonts_for_locales[locale]
    return font_name or "Arial"
end

return i18n