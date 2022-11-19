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

local State = require('cylibs/states/state')
local IdleState = setmetatable({}, {__index = State })
IdleState.__index = IdleState

function IdleState.new(action_queue)
	local self = setmetatable(State.new('Idle', L{'Idle', 'Engaged'}), IdleState)
	self.action_queue = action_queue
	self.current_target_id = nil
	self.nearby_enemies = L{}
	return self
end

function IdleState:enter_state()
	State.enter_state(self)

	notice("Entering Idle state")

	self:get_user_events().action = windower.register_event('postrender', function()
		-- Re-calculate nearby enemies
		self:update_nearby_enemies_display(self:get_nearby_enemies())
	end)
end

function IdleState:leave_state()
	State.leave_state(self)

	notice("Finished IdleState")
	
	self.current_target_id = nil

	self.action_queue:clear()
end

-- Returns a list of nearby enemies
function IdleState:get_nearby_enemies()
	local result = L{}

	local mob_array = windower.ffxi.get_mob_array()
    for i, mob in pairs(mob_array) do
		if mob and math.sqrt(mob.distance) < 30 and not mob.in_party and not mob.in_alliance then
			result:append(mob)
		end
    end
end

function IdleState:update_nearby_enemies_display()
	for mob in self.nearby_enemies:it() do
		-- TODO: update enemy in display
	end 
end

return IdleState



