---------------------------
-- Action representing the player casting a spell.
-- @class module
-- @name SpellAction

require('vectors')
require('math')
require('logger')
require('lists')

local res = require('resources')

local Action = require('cylibs/actions/action')
local SpellAction = setmetatable({}, {__index = Action })
SpellAction.__index = SpellAction

function SpellAction.new(x, y, z, spell_id, target_index, player)
	local self = setmetatable(Action.new(x, y, z), SpellAction)
	self.spell_id = spell_id
	self.target_index = target_index
	self.player = player

	if target_index == nil then
		self.target_index = windower.ffxi.get_player().index
	end

	self.user_events = {}

	self:debug_log_create(self:gettype())

 	return self
end

function SpellAction:destroy()
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
	if self.unable_to_cast_id then
		self.player:on_unable_to_cast():removeAction(self.spell_interrupted_id)
	end

	self.player = nil

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function SpellAction:can_perform()
	if L(windower.ffxi.get_player().buffs):contains(L{2,7,14,19,28,29}) then
		return false
	end

	if not spell_util.can_cast_spell(self.spell_id) then
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

	return false
end

function SpellAction:perform()
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
			function(p, spell_id, _)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						coroutine.sleep(1)
						self:complete(true)
					end
				end
			end)

	self.spell_interrupted_id = self.player:on_spell_interrupted():addAction(
			function(p, spell_id)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						coroutine.sleep(1)
						self:complete(false)
					end
				end
			end)

	self.unable_to_cast_id = self.player:on_unable_to_cast():addAction(
			function(p)
				if p:get_mob().id == windower.ffxi.get_player().id then
					self:complete(false)
				end
			end)

	windower.send_command('@input /ma "'..spell.name..'" '..target.id)
end

function SpellAction:getspellid()
	return self.spell_id
end

function SpellAction:gettargetindex()
	return self.target_index
end

function SpellAction:gettype()
	return "spellaction"
end

function SpellAction:getrawdata()
	local res = {}
	
	res.spellaction = {}
	res.spellaction.x = self.x
	res.spellaction.y = self.y
	res.spellaction.z = self.z
	
	return res
end

function SpellAction:getidentifier()
	return self.spell_id
end

function SpellAction:copy()
	return SpellAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function SpellAction:is_equal(action)
	if action == nil then return false end
	return self:gettype() == action:gettype()
			and self:getspellid() == action:getspellid()
			and self:gettargetindex() == action:gettargetindex()
end

function SpellAction:tostring()
    return "SpellAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return SpellAction



