--[[Copyright © 2019, Cyrite

Farm v1.0.0

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

local ProcTracker = {}
ProcTracker.__index = ProcTracker

weaponskills = L{
	{weapon="Dagger", en="Cyclone"},
	{weapon="Dagger", en="Energy Drain"},
	{weapon="Sword", en="Red Lotus Blade"},
	{weapon="Sword", en="Seraph Blade"},
	{weapon="GreatSword", en="Freezebite"},
	{weapon="Scythe", en="Shadow of Death"},
	{weapon="Polearm", en="Raiden Thrust"},
	{weapon="Katana", en="Blade: Ei"},
	{weapon="GreatKatana", en="Tachi: Jinpu"},
	{weapon="GreatKatana", en="Tachi: Koki"},
	{weapon="Club", en="Seraph Strike"},
	{weapon="Staff", en="Earth Crusher"},
	{weapon="Staff", en="Sunburst"},
}

function ProcTracker.new()
	local self = setmetatable({
		weaponskills_used = L{};
		user_events = {};
	}, ProcTracker)
	return self
end

function ProcTracker:start()
	user_events.action_message = windower.register_event('action message', function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		-- Mob dead or debuff wears off
		if T{6,20,113,406,605,646}:contains(message_id) then
			self.debuffed_mobs[target_id] = nil
		elseif T{204,206}:contains(message_id) then
			if self.debuffed_mobs[target_id] then
				self.debuffed_mobs[target_id][param_1] = nil
				if self.debuff_events['lose debuff'] ~= nil then
					self.debuff_events['lose debuff'](target_id, param_1)
				end
			end
		end
	end)

	user_events.message = windower.register_event('action', function(actionpacket)
		local action = ActionPacket.new(actionpacket)
		
		if actionpacket:get_category_string() == 
	
		-- Debuff lands
		if act.category == 4 then
			if act.targets[1].actions[1].message == 2 or act.targets[1].actions[1].message == 252 then
				if T{23,24,25,230,231,232}:contains(act.param) then
					--apply_dot(act.targets[1].id, act.param)
				elseif helixes:contains(act.param) then
					--apply_helix(act.targets[1].id, act.param)
				end
			elseif T{236,237,268,271}:contains(act.targets[1].actions[1].message) then
				local effect = act.targets[1].actions[1].param
				local target = act.targets[1].id
				local spell = act.param

				if not self.debuffed_mobs[target] then
					self.debuffed_mobs[target] = {}
				end

				if debuffs[effect] and debuffs[effect]:contains(spell) then
					self.debuffed_mobs[target][effect] = spell
					
					if self.debuff_events['gain debuff'] ~= nil then
						self.debuff_events['gain debuff'](target, effect)
					end
				end
			end
		end
	end)
end

function ProcTracker:stop()
	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
end

function ProcTracker:register_event(event_name, event_handler)
	self.debuff_events[event_name] = event_handler
end

function ProcTracker:unregister_event(event_name)
	self.debuff_events[event_name] = nil
end

return ProcTracker



