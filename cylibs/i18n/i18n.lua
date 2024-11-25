---------------------------
-- Utility functions for i18n.
-- @class module
-- @name i18n

local res = require('resources')

local i18n = {}

local locale = windower.ffxi.get_info().language
local translations = T{}

i18n.Locale = {}
i18n.Locale.English = 'en'
i18n.Locale.Japanese = 'ja'

function i18n.init(new_locale, translation_path)
    locale = new_locale
    translations = require(translation_path)
end

function i18n.current_locale()
    return locale
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

function i18n.resource(resource_name, key, value)
    if S{ 'en', 'ens' }:contains(key) and locale == i18n.Locale.English then
        return value
    end
    local item = res[resource_name]:with(key, value)
    if item then
        return item[locale]
    end
    return 'Unknown'
end

return i18n