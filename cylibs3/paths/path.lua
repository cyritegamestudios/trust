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

require('luau')
require('tables')
require('lists')
require('logger')

local WalkAction = require('cylibs/actions/walk')
local NpcAction = require('cylibs/actions/npc')
local WaitAction = require('cylibs/actions/wait')

local Path = {}
Path.__index = Path

function Path.new(settings)
  local self = setmetatable({
	actions = L{};
	autoreverse = settings.autoreverse;
	repeatdelay = settings.repeatdelay;
	zoneid = settings.zoneid;
	user_events = {};
  }, Path)
  if settings.zoneid == nil then
	notice('pee')
  end
  self.actions = Path.parse_actions(L{table.extract(settings.actions)})
  return self
end

function Path.parse_actions(actions)
	notice(actions)
	local result = T{}
	--for action in actions:it() do
	--	local new_action = nil
		--notice(action)
		--local index = tonumber(i)
		--if index then
		--	notice(action:tostring())
		--	result[index] = WalkAction.new(action.x, action.y, action.z)
		--end
	--end
	return result
end

function Path:get_actions()
	return self.actions
end

return Path



