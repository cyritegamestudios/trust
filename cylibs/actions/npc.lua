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

require('vectors')
require('math')
require('logger')

local packets = require('packets')

local Action = require('cylibs/actions/action')
local NpcAction = setmetatable({}, { __index = Action })
NpcAction.__index = NpcAction

function NpcAction.new(x, y, z, npc_id, category)
    local self = setmetatable(Action.new(x, y, z), NpcAction)
    self.npc_id = npc_id
    self.category = category
    return self
end

function NpcAction:perform()
    self:interact_with_npc(self:get_target_id(), self:get_category())
end

function NpcAction:cancel()
    if self.observer_id ~= -1 then
        windower.unregister_event(self.observer_id)
    end

    Action.cancel(self)
end

function NpcAction:interact_with_npc(npc_id, category)
    if self:is_cancelled() then
        return
    end

    local p = packets.new('outgoing', 0x01A)

    local mob = windower.ffxi.get_mob_by_id(npc_id)
    if not mob then
        self:complete(false)
        return
    end

    p['Target'] = mob.id
    p['Target Index'] = mob.index
    p['Category'] = category
    p['X Offset'] = 0
    p['Z Offset'] = 0
    p['Y Offset'] = 0

    notice("Performing action on NPC %s":format(mob.name))

    self.observer_id = -1
    --[[self.observer_id = windower.register_event('incoming chunk', function(id, data)
      --if id == 0x036 then
      --  local p = packets.parse('incoming', data)

      --  local actor_id = p['Actor']
      --  if actor_id == npc_id then
      --    windower.unregister_event(observer_id)

      --    self.completion(true)
      --	self.completion = false
      --  end
      if id == 0x052 then
          if self:is_cancelled() then
              return
          end

          windower.unregister_event(self.observer_id)

          self.completion(true)
          self.completion = false
      end
    end)--]]

    packets.inject(p)

    coroutine.sleep(1)

    self:complete()
end

function NpcAction:gettype()
    return "npcaction"
end

function NpcAction:getrawdata()
    local res = {}

    res.npcaction = {}
    res.npcaction.x = self.x
    res.npcaction.y = self.y
    res.npcaction.z = self.z
    res.npcaction.npc_id = self:get_target_id()
    res.npcaction.category = self:get_category()

    return res
end

function NpcAction:get_target_id()
    return self.npc_id
end

function NpcAction:get_category()
    return self.category
end

function NpcAction:copy()
    return NpcAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_target_id(), self:get_category())
end

function NpcAction:tostring()
    local mob = windower.ffxi.get_mob_by_id(self.npc_id)
    return "NpcAction %s":format(mob.name)
end

return NpcAction




