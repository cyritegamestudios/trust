local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')

local Action = require('cylibs/actions/action')
local LoadThemeAction = setmetatable({}, { __index = Action })
LoadThemeAction.__index = LoadThemeAction

function LoadThemeAction.new()
    local self = setmetatable(Action.new(0, 0, 0), LoadThemeAction)
    return self
end

function LoadThemeAction:perform()
    CollectionView.setDefaultStyle(FFXIClassicStyle.default())
    CollectionView.setDefaultBackgroundStyle(FFXIClassicStyle.background())

    self:complete(true)
end

function LoadThemeAction:gettype()
    return "loadthemeaction"
end

function LoadThemeAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadThemeAction:tostring()
    return "Loading theme"
end

return LoadThemeAction




