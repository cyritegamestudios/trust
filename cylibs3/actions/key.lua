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
local KeyAction = setmetatable({}, { __index = Action })
KeyAction.__index = KeyAction

function KeyAction.new(x, y, z, key)
    local self = setmetatable(Action.new(x, y, z), KeyAction)
    self.key = key
    return self
end

function KeyAction:perform()
    windower.send_command('setkey ' .. self.key .. ' down')
    coroutine.sleep(.1)
    windower.send_command('setkey ' .. self.key .. ' up')

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
    return "KeyAction key: %s":format
    (self.key)
end

return KeyAction




