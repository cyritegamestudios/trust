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
i18n.Locale.Default = i18n.Locale[locale]

local gearswap_locale = i18n.Locale.English

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

    translations[new_locale] = require(translations_for_locales[new_locale])

    i18n.onLocaleChanged():trigger(new_locale)
end

function i18n.current_gearswap_locale()
    return gearswap_locale
end

-------
-- Sets the current GearSwap locale.
-- @tparam i18n.Locale locale Locale (e.g. 'en', 'jp')
function i18n.set_current_gearswap_locale(new_locale)
    if new_locale == gearswap_locale then
        return
    end
    gearswap_locale = new_locale
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

function i18n.get_item(resource_name, key, value, fields)
    local table = windower.trust.resources[resource_name]
    if table then
        return table:where(string.format("%s == \"%s\"", key, value), fields):first()
    else
        return res[resource_name]:with(key, value) or res[resource_name]:with(key, value:lower())
    end
end

function i18n.resource(resource_name, key, value, output_locale)
    local locale = output_locale or locale
    if S{ 'en', 'ens' }:contains(key) and locale == i18n.Locale.English then
        return value:length() > 1 and value:slice(0, 1):upper()..value:slice(2) or value
    end
    local item = i18n.get_item(resource_name, key, value, L{ locale })
    if item then
        local text = item[locale]
        if locale == i18n.Locale.English then
            text = text:gsub("^%l", string.upper)
        end
        return text
    end
    return 'Unknown'
end

function i18n.resource_long(resource_name, key, value)
    if S{ 'en', 'ens' }:contains(key) and locale == i18n.Locale.English then
        return value:length() > 1 and value:slice(0, 1):upper()..value:slice(2) or value
    end
    local item = res[resource_name]:with(key, value) or res[resource_name]:with(key, value:lower())
    if item then
        local text = item[locale..'l']
        if locale == i18n.Locale.English then
            text = text:gsub("^%l", string.upper)
        end
        return text
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

-------
-- Returns the character set for a regex in the current locale.
-- @treturn string Character set for regex
function i18n.get_regex_character_set()
    if i18n.current_locale() == i18n.Locale.Japanese then
        return "%a"
    else
        return "%a"
    end
end

return i18n