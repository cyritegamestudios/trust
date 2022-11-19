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

require('tables')
require('lists')
require('logger')

local PlayerUtil = require('cylibs/util/player_util')
local Path = require('cylibs/paths/path')

local WeaponSkillAction = require('cylibs/actions/weapon_skill')

local State = require('cylibs/states/state')
local RunState = setmetatable({}, {__index = State })
RunState.__index = RunState

function RunState.new(action_queue, path_file_name)
	local self = setmetatable(State.new('Running', L{'Idle', 'Engaged'}), RunState)
	self.action_queue = action_queue
	self.path = Path.new(path_file_name)
	self.user_events = {}
	return self
end

function RunState:enter_state()
	notice("Entering Run state")
	
	self.user_events.action = windower.register_event('postrender', function()
	
	end)
end

function RunState:leave_state()
	notice("Finished EngageState")

	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
	
	self.user_events = {}
	
	self.action_queue:clear()
	
	PlayerUtil.stop_moving()
end

return RunState



