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

local ActionQueue = require('cylibs/actions/action_queue')
local CommandAction = require('cylibs/actions/command')
local AttackAction = require('cylibs/actions/attack')
local WaitAction = require('cylibs/actions/wait')

local State = require('cylibs/states/state')
local TrustIdleState = setmetatable({}, {__index = State })
TrustIdleState.__index = TrustIdleState

function TrustIdleState.new(action_queue, assist_mode)
	local self = setmetatable(State.new('Idle', L{'Idle', 'Engaged'}), TrustIdleState)
	self.action_queue = action_queue
	self.assist_mode = assist_mode
	self.current_target_id = nil
	self.user_events = {}
	return self
end

function TrustIdleState:clean_up()
	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
	
	self.user_events = {}
end

function TrustIdleState:enter_state()
	State.enter_state(self)

	self.user_events.time_change = windower.register_event('time change', function(new_time, old_time) 
		if self.assist_mode.value == 'Party' then
			local target = windower.ffxi.get_mob_by_target("bt")
			if target ~= nil and target.hpp > 0 and windower.ffxi.get_player().target_index ~= target.index then
				self:engage_target(target.id)
			end
		end
	end)
end

function TrustIdleState:leave_state()
	self:clean_up()
end

function TrustIdleState:engage_target(target_id)
	print("Engaging %i":format(target_id))

	local engage_action = AttackAction.new(target_id)
	self.action_queue:push_action(engage_action)
end

return TrustIdleState



