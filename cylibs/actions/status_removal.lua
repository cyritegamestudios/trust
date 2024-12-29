---------------------------
-- Action representing a status removal.
-- @class module
-- @name StatusRemovalAction

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local SpellCommand = require('cylibs/ui/input/chat/commands/spell')

local Action = require('cylibs/actions/action')
local StatusRemovalAction = setmetatable({}, {__index = Action })
StatusRemovalAction.__index = StatusRemovalAction

-- Called when a status removal has no effect
function StatusRemovalAction:on_status_removal_no_effect()
	return WindowerEvents.StatusRemoval.NoEffect
end

-- Called when a status effect is removed successfully
function StatusRemovalAction:on_status_removed()
	return self.status_removed
end

function StatusRemovalAction.new(x, y, z, spell_id, target_index, debuff_id, player)
	local conditions = L{
		NotCondition.new(L{InMogHouseCondition.new()}),
		MaxDistanceCondition.new(20),
		NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'mute', 'stun'}, 1)}, windower.ffxi.get_player().index),
		HasDebuffCondition.new(buff_util.buff_name(debuff_id)),
		MinManaPointsCondition.new(res.spells[spell_id].mp_cost or 0, windower.ffxi.get_player().index),
		SpellRecastReadyCondition.new(spell_id),
		ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
	}

	local self = setmetatable(Action.new(x, y, z, target_index or windower.ffxi.get_player().index, conditions), StatusRemovalAction)

	self.dispose_bag = DisposeBag.new()
	self.spell_id = spell_id
	self.debuff_id = debuff_id
	self.player = player
	self.user_events = {}

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

	self.dispose_bag:destroy()

	self.status_removed:removeAllActions()

	self.player = nil

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function StatusRemovalAction:perform()
	windower.ffxi.run(false)

	self.dispose_bag:add(self.player:on_spell_finish():addAction(
			function(p, spell_id, targets)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						for _,target in pairs(targets) do
							for _,action in pairs(target.actions) do
								if L{75, 283}:contains(action.message) then
									self:on_status_removal_no_effect():trigger(self.spell_id, target.id, self.debuff_id)
								else
									self:on_status_removed():trigger(self, self.spell_id, target.id, self.debuff_id)
								end
							end
						end
						self:complete(true)
					end
				end
			end), self.player:on_spell_finish())

	self.dispose_bag:add(self.player:on_spell_interrupted():addAction(
			function(p, spell_id)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
						self:complete(false)
					end
				end
			end), self.player:on_spell_interrupted())

	local target = windower.ffxi.get_mob_by_index(self.target_index or windower.ffxi.get_player().index)

	local spell = SpellCommand.new(spell_util.spell_name(self.spell_id), target.id)
	spell:run(true)
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
	local spell = res.spells:with('id', self.spell_id)
	local target = windower.ffxi.get_mob_by_index(self.target_index)
	return spell.en..' → '..target.name
end

function StatusRemovalAction:debug_string()
    return "StatusRemovalAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return StatusRemovalAction



