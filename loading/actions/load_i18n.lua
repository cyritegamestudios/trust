local localization_util = require('cylibs/util/localization_util')

local Action = require('cylibs/actions/action')
local Loadi18nAction = setmetatable({}, { __index = Action })
Loadi18nAction.__index = Loadi18nAction

function Loadi18nAction.new()
    local self = setmetatable(Action.new(0, 0, 0), Loadi18nAction)
    return self
end

function Loadi18nAction:load_i18n_settings()
    local locale = i18n.Locale.English

    local language = windower.ffxi.get_info().language
    if language:lower() == 'japanese' then
        locale = i18n.Locale.Japanese
    end

    local translations_for_locale = {
        [i18n.Locale.English] = 'translations/en',
        [i18n.Locale.Japanese] = 'translations/ja',
    }

    local font_for_locale = {
        [i18n.Locale.English] = addon_settings:getSettings().locales.font_names.english,
        [i18n.Locale.Japanese] = addon_settings:getSettings().locales.font_names.japanese,
    }

    i18n.init(locale, translations_for_locale, font_for_locale)
end

function Loadi18nAction:perform()
    localization_util.set_should_use_client_locale(addon_settings:getSettings().locales.actions.use_client_locale or false)

    self:load_i18n_settings()

    self:complete(true)
end

function Loadi18nAction:gettype()
    return "loadi18naction"
end

function Loadi18nAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function Loadi18nAction:tostring()
    return "Loading languages"
end

return Loadi18nAction




