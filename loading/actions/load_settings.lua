local Action = require('cylibs/actions/action')
local LoadSettingsAction = setmetatable({}, { __index = Action })
LoadSettingsAction.__index = LoadSettingsAction

function LoadSettingsAction.new()
    local self = setmetatable(Action.new(0, 0, 0), LoadSettingsAction)
    return self
end

function LoadSettingsAction:load_settings()
    return coroutine.create(function()
        addon_settings = TrustAddonSettings.new()
        addon_settings:loadSettings()
        coroutine.yield(true)
    end)
end

function LoadSettingsAction:perform()
    local success = coroutine.resume(self:load_settings())

    self:complete(success)
end

function LoadSettingsAction:gettype()
    return "loadsettingsaction"
end

function LoadSettingsAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadSettingsAction:tostring()
    return "Loading addon settings"
end

return LoadSettingsAction




