--[[Copyright © 2019, Cyrite

Path v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

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




