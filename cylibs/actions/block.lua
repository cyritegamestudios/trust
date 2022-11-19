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

local Action = require('cylibs/actions/action')
local BlockAction = setmetatable({}, { __index = Action })
BlockAction.__index = BlockAction

function BlockAction.new(block)
    local self = setmetatable(Action.new(0, 0, 0), BlockAction)
    self.block = block
    return self
end

function BlockAction:destroy()
    Action.destroy(self)
    self.block = nil
end

function BlockAction:perform()
    if self:is_cancelled() then
        self:complete(false)
        return
    end
    self.block()

    self:complete(true)
end

function BlockAction:gettype()
    return "blockaction"
end

function BlockAction:getrawdata()
    return nil
end

function BlockAction:copy()
    return BlockAction.new(self.block)
end

function BlockAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

function BlockAction:tostring()
    return "BlockAction"
end

return BlockAction




