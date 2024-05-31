---------------------------
-- Action representing the player casting a spell.
-- @class module
-- @name SpellAction

require('vectors')
require('math')
require('logger')
require('lists')

local DisposeBag = require('cylibs/events/dispose_bag')
local res = require('resources')
local ValidSpellTargetCondition = require('cylibs/conditions/valid_spell_target')

local Action = require('cylibs/actions/action')
local SpellAction = setmetatable({}, {__index = Action })
SpellAction.__index = SpellAction

function SpellAction.new(x, y, z, spell_id, target_index, player, conditions)
	local conditions = (conditions or L{}):extend(L{
		NotCondition.new(L{InMogHouseCondition.new()}),
		MaxDistanceCondition.new(20),
		NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'mute', 'Invisible'}, 1)}, windower.ffxi.get_player().index),
		MinManaPointsCondition.new(res.spells[spell_id].mp_cost or 0),
		SpellRecastReadyCondition.new(spell_id),
		ValidSpellTargetCondition.new(res.spells[spell_id].en, alter_ego_util.untargetable_alter_egos()),
	})

	local self = setmetatable(Action.new(x, y, z, target_index, conditions), SpellAction)

	self.dispose_bag = DisposeBag.new()
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

	self.dispose_bag:destroy()

	self.player = nil

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function SpellAction:perform()
	windower.ffxi.run(false)

	self.dispose_bag:add(self.player:on_spell_finish():addAction(
			function(p, spell_id, _)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						coroutine.sleep(1)
						self:complete(true)
					end
				end
			end), self.player:on_spell_finish())

	self.dispose_bag:add(self.player:on_spell_interrupted():addAction(
			function(p, spell_id)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						coroutine.sleep(1)
						self:complete(false)
					end
				end
			end), self.player:on_spell_interrupted())

	self.dispose_bag:add(self.player:on_unable_to_cast():addAction(
			function(p)
				if p:get_mob().id == windower.ffxi.get_player().id then
					self:complete(false)
				end
			end), self.player:on_unable_to_cast())

	local target = windower.ffxi.get_mob_by_index(self.target_index)
	local spell = res.spells[self.spell_id]

	if windower.ffxi.get_info().language:lower() == 'japanese' then
		windower.chat.input("/ma %s ":format(spell.en)..target.id)
	else
		windower.chat.input('/ma "%s" ':format(spell.en)..target.id)
	end
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
	if target.name == windower.ffxi.get_player().name then
		return spell.en
	end
	return spell.en..' → '..target.name
end

function SpellAction:debug_string()
	return "SpellAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return SpellAction



