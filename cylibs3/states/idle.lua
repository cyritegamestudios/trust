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
local FollowAction = require('cylibs/actions/follow')

local State = require('cylibs/states/state')
local IdleState = setmetatable({}, {__index = State })
IdleState.__index = IdleState

function IdleState.new(action_queue, engagedistance, target_mobs)
	local self = setmetatable(State.new('Idle', L{'Idle', 'Engaged'}), IdleState)
	self.action_queue = action_queue
	self.engagedistance = engagedistance
	self.target_mobs = target_mobs
	self.current_target_id = nil
	self.user_events = {}
	return self
end

function IdleState:enter_state()
	State.enter_state(self)

	notice("Entering Idle state")
	
	PlayerUtil.stop_moving()
	
	-- FIXME:(scretella) get rid of this
	--windower.send_command('path enable')
	
	self.user_events.action = windower.register_event('postrender', function()
		if self:get_time_in_state() < 5 then
			return
		end
		if self.current_target_id ~= nil then
			local mob = windower.ffxi.get_mob_by_id(self.current_target_id)
			if mob ~= nil and mob.claim_id == windower.ffxi.get_player().id or mob.claim_id == 0 then
				if mob.distance < 10 then
					self:engage_target(mob.id)
				end
			else
				PlayerUtil.stop_moving()

				self.current_target_id = nil
			end
		else
			local mob = PlayerUtil.find_closest_mob(self.target_mobs, L{})
			if mob and mob.distance < self.engagedistance then
				-- FIXME:(scretella) get rid of this
				--windower.send_command('path disable')
				
				self.current_target_id = mob.id
				
				-- FIXME:(scretella) get rid of this hack
				coroutine.schedule(function()
					local follow_action = FollowAction.new(mob.id)
					self.action_queue:push_action(follow_action)
				end, 1)
				
			end
		end
	end)
end

function IdleState:leave_state()
	notice("Finished IdleState")
	
	self.current_target_id = nil

	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
	
	self.user_events = {}
end

function IdleState:engage_target(target_id)
	self.current_target_id = nil
	
	local engage_action = AttackAction.new(target_id)
	self.action_queue:push_action(engage_action)
	
	self:leave_state()
end

return IdleState



