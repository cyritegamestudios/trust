require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local CommandAction = setmetatable({}, { __index = Action })
CommandAction.__index = CommandAction

function CommandAction.new(x, y, z, command)
    local self = setmetatable(Action.new(x, y, z), CommandAction)
    self.command = command
    return self
end

function CommandAction:perform()
    windower.chat.input('%s':format(self:get_command()))

    self:complete(true)
end

function CommandAction:get_command()
    return self.command
end

function CommandAction:gettype()
    return "commandaction"
end

function CommandAction:getrawdata()
    local res = {}

    res.commandaction = {}
    res.commandaction.x = self.x
    res.commandaction.y = self.y
    res.commandaction.z = self.z
    res.commandaction.command = self:get_command()

    return res
end

function CommandAction:copy()
    return CommandAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_command())
end

function CommandAction:is_equal(action)
    if action == nil then
        return false
    end

    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function CommandAction:tostring()
    return "CommandAction command: %s":format(self.command)
end

return CommandAction




