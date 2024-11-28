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

i18n.Locale = {}
i18n.Locale.English = 'en'
i18n.Locale.Japanese = 'ja'

local fonts_for_locales = T{
    [i18n.Locale.English] = "Arial",
    [i18n.Locale.Japanese] = "MS Gothic",
}

-------
-- Event called when the locale is changed.
-- @tparam Luvent Event
function i18n.onLocaleChanged()
    return locale_changed
end

function i18n.init(new_locale, translation_path, font_map)
    locale = new_locale
    translations = require(translation_path)
    fonts_for_locales = font_map
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
    local translation = translations:with('key', key)
    if translation then
        return translation.singular
    end
    return key
end

-------
-- Sets the locale to be used when localization action commands (e.g. /ma <spell_name> <t>)
-- @tparam string locale Locale (e.g. 'en', 'jp')
function i18n.translate_any(text)
    if res.elements:with('en', text) then
        return i18n.resource('elements', 'en', text)
    elseif res.spells:with('en', text) then
        return i18n.resource('spells', 'en', text)
    elseif res.job_abilities:with('en', text) then
        return i18n.resource('job_abilities', 'en', text)
    elseif res.weapon_skills:with('en', text) then
        return i18n.resource('weapon_skills', 'en', text)
    end
    return text
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