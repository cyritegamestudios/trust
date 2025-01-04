local Action = require('cylibs/actions/action')
local LoadLoggerAction = setmetatable({}, { __index = Action })
LoadLoggerAction.__index = LoadLoggerAction

function LoadLoggerAction.new()
    local self = setmetatable(Action.new(0, 0, 0), LoadLoggerAction)
    return self
end

function LoadLoggerAction:perform()
    _libs.logger.settings.logtofile = addon_settings:getSettings().logging.logtofile
    _libs.logger.settings.defaultfile = 'logs/'..windower.ffxi.get_player().name..'_'..string.format("%s.log", os.date("%m-%d-%y"))

    logger.isEnabled = addon_settings:getSettings().logging.enabled

    self:complete(true)
end

function LoadLoggerAction:gettype()
    return "loadloggeraction"
end

function LoadLoggerAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadLoggerAction:tostring()
    return "Loading logger"
end

return LoadLoggerAction




