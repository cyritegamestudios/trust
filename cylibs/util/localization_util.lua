---------------------------
-- Utility functions for localization.
-- @class module
-- @name LocalizationUtil

local res = require('resources')

local localization_util = {}

local translation_cache = {}

-------
-- Encodes the given text to be output into the chat log. Pass in the UTF-8 string
-- and it will properly encode it for NA and JP clients. For JP clients, pass in the
-- Japanese text.
-- @tparam string text Text to encode.
-- @treturn string Encoded text
function localization_util.encode(text, language)
    language = language or windower.ffxi.get_info().language:lower()
    if language == 'japanese' then
        return windower.to_shift_jis(text)
    else
        return text
    end
end

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

-------
-- Comma separates elements of a list and returns as a string
-- @tparam list list List to separate
-- @treturn string Comma separated list of elements
function localization_util.commas(list, join_word)
    join_word = join_word or "and"
    if list:length() == 0 then
        return ""
    end
    if list:length() == 1 then
        return list[1]
    end
    local result = list[1]
    for i = 2, list:length() do
        if i < list:length() or join_word:length() == 0 then
            result = result..', '..list[i]
        else
            result = result..' '..join_word..' '..list[i]
        end
    end
    if result == nil then
        print(list, list:length())
    end
    result = result:sub(1, -1)
    return result
end

function localization_util.time_format(timestamp)
    local diff = timestamp - os.time()
    if diff < 0 then
        return "00:00:00"
    end

    local hours = math.floor(diff / 3600)
    local minutes = math.floor((diff % 3600) / 60)
    local seconds = diff % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function localization_util.format(string, inverted)
    if inverted then
        return "Not "..string
    else
        return string
    end
end

function localization_util.join(list, separator)
    if list:length() == 0 then
        return ""
    end
    if list:length() == 1 then
        return list[1]
    end
    local result = list[1]
    for i = 2, list:length() do
        result = result..' '..separator..' '..list[i]
    end
    result = result:sub(1, -1)
    return result
end

-------
-- Truncates the given text.
-- @tparam string text Text to truncate
-- @tparam number max_num_chars Maximum number of characters
-- @treturn string Truncated text
function localization_util.truncate(text, max_num_chars)
    if text:length() <= max_num_chars then
        return text
    end
    return text:slice(1, max_num_chars - 3).."…"
end

-------
-- Converts the input text to first upper case.
-- @tparam string text Text to truncate
-- @treturn string Text with first character capitalized and the remaining characters lower cased.
function localization_util.firstUpper(text)
    return (text or ""):gsub("(%a)(%w*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

return localization_util