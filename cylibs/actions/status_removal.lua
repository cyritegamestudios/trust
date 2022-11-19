require('vectors')
require('math')
require('logger')
require('lists')

local Event = require('cylibs/events/Luvent')

local Action = require('cylibs/actions/action')
local StatusRemovalAction = setmetatable({}, {__index = Action })
StatusRemovalAction.__index = StatusRemovalAction

-- Called when a status removal has no effect
function StatusRemovalAction:on_status_removal_no_effect()
	return self.status_removal_no_effect
end

-- Called when a status effect is removed successfully
function StatusRemovalAction:on_status_removed()
	return self.status_removed
end

function StatusRemovalAction.new(x, y, z, spell_id, target_index, debuff_id, player)
	local self = setmetatable(Action.new(x, y, z), StatusRemovalAction)
	self.spell_id = spell_id
	self.target_index = target_index
	self.debuff_id = debuff_id
	self.player = player

	if target_index == nil then
		self.target_index = windower.ffxi.get_player().index
	end

	self.user_events = {}
	self.status_removal_no_effect = Event.newEvent()
	self.status_removed = Event.newEvent()

	self:debug_log_create(self:gettype())

 	return self
end

function StatusRemovalAction:destroy()
	if self.user_events then
		for _,event in pairs(self.user_events) do
			windower.unregister_event(event)
		end
	end

	if self.spell_finish_id then
		self.player:on_spell_finish():removeAction(self.spell_finish_id)
	end
	if self.spell_interrupted_id then
		self.player:on_spell_interrupted():removeAction(self.spell_interrupted_id)
	end

	self.player = nil

	self.status_removal_no_effect:removeAllActions()
	self.status_removed:removeAllActions()

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function StatusRemovalAction:can_perform()
	if L(windower.ffxi.get_player().buffs):contains(L{2,7,14,19,28,29}) then
		return false
	end

	local target = windower.ffxi.get_mob_by_index(self.target_index)
	if target and target.distance:sqrt() > 21 then
		return false
	end

	local spell = res.spells:with('id', self.spell_id)
	if spell and windower.ffxi.get_player().vitals.mp > spell.mp_cost then
		return true
	end

	local target = windower.ffxi.get_mob_by_index(self.target_index)
	if not target or not party_util.get_buffs(target.id):contains(self.debuff_id) then
		return false
	end
	return true
end

function StatusRemovalAction:perform()
	if self:is_cancelled() then
		self:complete(false)
		return
	end

	windower.ffxi.run(false)

	local target = windower.ffxi.get_mob_by_index(self.target_index)

	local all_spells = windower.ffxi.get_spells()
	local recast_times = windower.ffxi.get_spell_recasts()

	if target == nil or self.spell_id == nil or all_spells[self.spell_id] == nil or recast_times[self.spell_id] > 0 then
		self:complete(false)
		return
	end

	local spell = res.spells:with('id', self.spell_id)
	if spell == nil then
		self:complete(false)
		return
	end

	self.spell_finish_id = self.player:on_spell_finish():addAction(
			function(p, spell_id, targets)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						for _,target in pairs(targets) do
							for _,action in pairs(target.actions) do
								if L{75, 283}:contains(action.message) then
									self:on_status_removal_no_effect():trigger(self, self.spell_id, target.id, self.debuff_id)
								else
									self:on_status_removed():trigger(self, self.spell_id, target.id, self.debuff_id)
								end
							end
						end
						self:complete(true)
					end
				end
			end)

	self.spell_interrupted_id = self.player:on_spell_interrupted():addAction(
			function(p, spell_id)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						self:complete(false)
					end
				end
			end)

	windower.send_command('@input /ma "'..spell.name..'" '..target.id)
end

function StatusRemovalAction:getspellid()
	return self.spell_id
end

function StatusRemovalAction:gettargetindex()
	return self.target_index
end

function StatusRemovalAction:gettype()
	return "statusremovalaction"
end

function StatusRemovalAction:getrawdata()
	local res = {}
	
	res.statusremovalaction = {}
	res.statusremovalaction.x = self.x
	res.statusremovalaction.y = self.y
	res.statusremovalaction.z = self.z
	
	return res
end

function StatusRemovalAction:getidentifier()
	return self.spell_id
end


function StatusRemovalAction:copy()
	return StatusRemovalAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function StatusRemovalAction:is_equal(action)
	if action == nil then return false end
	return self:gettype() == action:gettype()
			and self:getspellid() == action:getspellid()
			and self:gettargetindex() == action:gettargetindex()
end

function StatusRemovalAction:tostring()
    return "StatusRemovalAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return StatusRemovalAction



