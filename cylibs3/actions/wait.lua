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
local WaitAction = setmetatable({}, { __index = Action })
WaitAction.__index = WaitAction

function WaitAction.new(x, y, z, duration)
    local self = setmetatable(Action.new(x, y, z), WaitAction)
    self.duration = duration
    self:debug_log_create(self:gettype())
    return self
end

function WaitAction:destroy()
    Action.destroy(self)

    self:debug_log_destroy(self:gettype())
end

function WaitAction:perform()
    coroutine.sleep(self.duration)

    self:complete(true)
end

function WaitAction:get_duration()
    return self.duration
end

function WaitAction:gettype()
    return "waitaction"
end

function WaitAction:getrawdata()
    local res = {}

    res.waitaction = {}
    res.waitaction.x = self.x
    res.waitaction.y = self.y
    res.waitaction.z = self.z
    res.waitaction.duration = self:get_duration()

    return res
end

function WaitAction:copy()
    return WaitAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_duration())
end

function WaitAction:tostring()
    return "WaitAction delay: %d":format(self:get_duration())
end

return WaitAction




