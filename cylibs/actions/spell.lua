---------------------------
-- Action representing the player casting a spell.
-- @class module
-- @name SpellAction

local DisposeBag = require('cylibs/events/dispose_bag')
local IsStandingCondition = require('cylibs/conditions/is_standing')
local res = require('resources')
local SpellCommand = require('cylibs/ui/input/chat/commands/spell')
local Timer = require('cylibs/util/timers/timer')
local ValidSpellTargetCondition = require('cylibs/conditions/valid_spell_target')

local Action = require('cylibs/actions/action')
local SpellAction = setmetatable({}, {__index = Action })
SpellAction.__index = SpellAction
SpellAction.__type = "SpellAction"

-- Tracks when the player's weaponskill lands (action packet
-- category 3). A cast sent within 2 seconds of that moment is
-- rejected by the weaponskill's action lock ("Unable to cast at
-- this time") -- Foe Requiem right after a Savage Blade is the
-- usual victim. The role-level holds (Debuffer, Singer) cannot
-- cover a spell that was already queued before the weaponskill
-- fired, so perform() itself waits the lock out here, at the one
-- point every cast passes through. Subscribed lazily on first
-- use so the events module is loaded by then.
local player_last_weaponskill_time = 0
local ws_tracker_started = false
local function start_ws_tracker()
	if ws_tracker_started then
		return
	end
	ws_tracker_started = true
	WindowerEvents.Action:addAction(function(act)
		local player = windower.ffxi.get_player()
		if player and act.actor_id == player.id and act.category == 3 then
			player_last_weaponskill_time = os.clock()
		end
	end)
	windower.register_event('zone change', function()
		player_last_weaponskill_time = 0
	end)
end

function SpellAction.new(x, y, z, spell_id, target_index, player, conditions)
	local conditions = (conditions or L{}):extend(L{
		IsStandingCondition.new(0.3, ">="),
		NotCondition.new(L{StatusCondition.new("Mount")}),
		NotCondition.new(L{InMogHouseCondition.new()}),
		MaxDistanceCondition.new(21),
		MinManaPointsCondition.new(res.spells[spell_id].mp_cost or 0, windower.ffxi.get_player().index),
		SpellRecastReadyCondition.new(spell_id),
		ValidSpellTargetCondition.new(res.spells[spell_id].en, alter_ego_util.untargetable_alter_egos()),
	})

	if res.spells[spell_id].type == 'Trust' then
		conditions:append(NotCondition.new(L{InTownCondition.new()}))
	end

	local self = setmetatable(Action.new(x, y, z, target_index, conditions), SpellAction)

	self.dispose_bag = DisposeBag.new()
	self.spell_id = spell_id
	self.identifier = spell_id
	self.player = player

	self:debug_log_create(self:gettype())

	start_ws_tracker()

 	return self
end

function SpellAction:destroy()
	self.dispose_bag:destroy()

	self.player = nil

	self:debug_log_destroy(self:gettype())

	Action.destroy(self)
end

function SpellAction:perform()
	windower.ffxi.run(false)

	-- Inside the weaponskill's action lock (see the tracker at the
	-- top of this file): hold the cast until the lock has passed
	-- instead of sending it to be rejected. The timer re-checks
	-- the clock, so a weaponskill landing during the wait simply
	-- extends it. The finish/interrupt handlers are registered in
	-- begin_cast, once the cast is really sent, so a delayed cast
	-- cannot be completed early by another cast of the same spell.
	local lock_remaining = 2 - (os.clock() - player_last_weaponskill_time)
	if lock_remaining > 0 then
		self.ws_lock_timer = Timer.scheduledTimer(0.25, lock_remaining)
		self.dispose_bag:addAny(L{ self.ws_lock_timer })
		self.dispose_bag:add(self.ws_lock_timer:onTimeChange():addAction(function()
			if os.clock() - player_last_weaponskill_time >= 2 then
				self.ws_lock_timer:cancel()
				self:begin_cast()
			end
		end), self.ws_lock_timer:onTimeChange())
		self.ws_lock_timer:start()
		return
	end

	self:begin_cast()
end

function SpellAction:begin_cast()
	if self:is_cancelled() then
		self:complete(false)
		return
	end

	self.dispose_bag:add(self.player:on_spell_finish():addAction(
			function(p, spell_id, _)
				if p:get_mob().id == windower.ffxi.get_player().id then
					if spell_id == self.spell_id then
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

	self.dispose_bag:add(self.player:on_unable_to_cast():addAction(
			function(p)
				if p:get_mob().id == windower.ffxi.get_player().id then
					self:complete(false)
				end
			end), self.player:on_unable_to_cast())

	local target = windower.ffxi.get_mob_by_index(self.target_index or windower.ffxi.get_player().index)

	local spell = SpellCommand.new(spell_util.spell_name(self.spell_id), target.id)
	spell:run(true)
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
	return self.identifier
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
		return i18n.resource('spells', 'en', spell.en)
	end
	return i18n.resource('spells', 'en', spell.en)..' → '..target.name
end

function SpellAction:debug_string()
	return "SpellAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return SpellAction



