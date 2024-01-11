---------------------------
-- Utility functions for localization.
-- @class module
-- @name LocalizationUtil

local res = require('resources')

local localization_util = {}

local translation_cache = {}

-------
-- Returns the auto translate entry for the given term, if it exists.
-- @tparam string term Term to translate
-- @treturn string Auto translate entry to use with windower.add_to_chat
function localization_util.translate(term)
    if not translation_cache[term] then
        local entry = res.auto_translates:with('english', term)
        translation_cache[term] = entry and 'CH>HC':pack(0xFD, 0x0202, entry.id, 0xFD) or term
    end
    return translation_cache[term]
end

return localization_util