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
	local conditions = L{
		MaxDistanceCondition.new(20),
		NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'mute'}, false)}),
		MinManaPointsCondition.new(res.spells[spell_id].mp_cost or 0),
		SpellRecastReadyCondition.new(spell_id),
		ValidTargetCondition.new(),
	}

	local self = setmetatable(Action.new(x, y, z, target_index, conditions), SpellAction)

	self.spell_id = spell_id
	self.player = player
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

function SpellAction:perform()
	windower.ffxi.run(false)

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

	local target = windower.ffxi.get_mob_by_index(self.target_index)
	local spell = res.spells[self.spell_id]

	windower.send_command('@input /ma "'..spell.name..'" '..target.id)
end

function SpellAction:getspellid()
	return self.spell_id
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
	local spell = res.spells[self:getspellid()]
	local target = windower.ffxi.get_mob_by_index(self.target_index)
	return spell.en..' → '..target.name
end

function SpellAction:debug_string()
	return "SpellAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return SpellAction



