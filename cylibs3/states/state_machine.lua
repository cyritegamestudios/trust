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
require('logger')
require('vectors')
require('lists')

local StateMachine = {}
StateMachine.__index = StateMachine

-- Creates a new state machine with the given states and transitions.
--
-- Params
-- states: A list of State objects
-- initial_state: Initial state
function StateMachine.new(states, initial_state)
  local self = setmetatable({
	current_state = initial_state;
	states = states;
  }, StateMachine)
  self.current_state:enter_state()
  
  return self
end

-- Transitions the StateMachine to the given state
function StateMachine:enter_state(new_state)
	if new_state == nil then
		return false
	end

	if self.current_state:can_transition_to_state(new_state) then
		self.current_state:leave_state()
		self.current_state = new_state
		
		self.current_state:enter_state()
	end
	
	return true
end

function StateMachine:get_state_by_name(name)
	local matches = self.states:filter(function(state)
		return state:get_name() == name
	end)
	return matches[1]
end

return StateMachine



