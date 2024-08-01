require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local KeyAction = setmetatable({}, { __index = Action })
KeyAction.__index = KeyAction
KeyAction.__class = "KeyAction"

function KeyAction.new(x, y, z, key)
    local self = setmetatable(Action.new(x, y, z), KeyAction)
    self.key = key
    return self
end

function KeyAction:destroy()
    Action.destroy(self)

    windower.send_command('setkey ' .. self.key .. ' up')
end

function KeyAction:perform()
    logger.notice(self.__class, 'perform', self.key, 'down')

    windower.send_command('setkey ' .. self.key .. ' down')
    coroutine.sleep(.1)
    windower.send_command('setkey ' .. self.key .. ' up')

    logger.notice(self.__class, 'perform', self.key, 'up')

    self:complete(true)
end

function KeyAction:get_key()
    return self.key
end

function KeyAction:gettype()
    return "keyaction"
end

function KeyAction:getrawdata()
    local res = {}

    res.keyaction = {}
    res.keyaction.x = self.x
    res.keyaction.y = self.y
    res.keyaction.z = self.z
    res.keyaction.key = self:get_key()

    return res
end

function KeyAction:copy()
    return KeyAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_key())
end

function KeyAction:tostring()
    return "KeyAction key: %s":format(self.key)
end

return KeyAction




