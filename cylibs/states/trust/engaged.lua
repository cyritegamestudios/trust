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

local BuffUtil = require('cylibs/util/buff_util')
local PlayerUtil = require('cylibs/util/player_util')

local FollowAction = require('cylibs/actions/follow')
local WeaponSkillAction = require('cylibs/actions/weapon_skill')
local SkillchainMaker = require('cylibs/battle/skillchain_maker')

local State = require('cylibs/states/state')
local EngagedState = setmetatable({}, {__index = State })
EngagedState.__index = EngagedState

function EngagedState.new(action_queue, auto_skillchain_mode)
	local self = setmetatable(State.new('Engaged', L{'Idle'}), EngagedState)
	self.action_queue = action_queue
	self.auto_skillchain_mode = auto_skillchain_mode
	self.user_events = {}
	self.skillchain_maker = SkillchainMaker.new()
	return self
end

function EngagedState:clean_up()
	self.skillchain_maker:disable()

	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
	
	self.user_events = {}
end

function EngagedState:enter_state()
	local target = windower.ffxi.get_mob_by_target("bt")
	if target ~= nil and target.hpp > 0 then
		local follow_action = FollowAction.new(target.id)
		self.action_queue:push_action(follow_action)
	end
	if self.auto_skillchain_mode ~= 'None' then
		self.skillchain_maker:enable()
	end
end

function EngagedState:leave_state()
	self:clean_up()

	windower.ffxi.follow()
	windower.ffxi.run(false)
end

function EngagedState:get_current_target()
	local target = windower.ffxi.get_mob_by_target("bt")
	return target
end

return EngagedState



