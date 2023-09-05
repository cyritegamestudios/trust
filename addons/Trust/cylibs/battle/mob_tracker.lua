---------------------------
-- Tracks debuffs on mobs.
-- @class module
-- @name MobTracker


require('tables')

local MobTracker = {}
MobTracker.__index = MobTracker

death_message_ids = T{6,20,113,406,605,646}
debuff_off_message_ids = T{204,206}

helixes = S{278,279,280,281,282,283,284,285,
    885,886,887,888,889,890,891,892}

debuffs = {
    [2] = S{253,259,678}, --Sleep
    [3] = S{220,221,225,350,351,716}, --Poison
    [4] = S{58,80,341,644,704}, --Paralyze
    [5] = S{254,276,347,348}, --Blind
    [6] = S{59,687,727}, --Silence
    [7] = S{255,365,722}, --Break
    [11] = S{258,531}, --Bind
    [12] = S{216,217,708}, --Gravity
    [13] = S{56,79,344,345,703}, --Slow
	[21] = S{286,472,884}, --addle/nocturne
	[28] = S{575,720,738,746}, --terror
	[31] = S{682}, --plague
	[136] = S{240,705}, --str down
	[137] = S{238}, --dex down
	[138] = S{237}, --VIT down
	[139] = S{236,535}, --AGI down
	[140] = S{235,572,719}, --int down
	[141] = S{239}, --mnd down
	[146] = S{524,699}, --accuracy down
	[147] = S{319,651,659,726}, --attack down
    [148] = S{610,841,842,882}, --Evasion Down
	[149] = S{717,728,651}, -- defense down
	[156] = S{112,707,725}, --Flash
	[167] = S{656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[193] = S{463,471,376,377}, --lullabies
	[194] = S{421,422,423}, --elegy
	[217] = S{454,455,456,457,458,459,460,461,871,872,873,874,875,876,877,878}, --threnodies
    [404] = S{843,844,883}, --Magic Evasion Down
	[597] = S{879}, --inundation

}

hierarchy = {
    [23] = 1, --Dia
    [24] = 3, --Dia II
    [25] = 5, --Dia III
    [230] = 2, --Bio
    [231] = 4, --Bio II
    [232] = 6, --Bio III
}

function MobTracker.new()
	local self = setmetatable({
		debuff_events ={};
		user_events = {};
		debuffed_mobs = T{}
	}, MobTracker)
	return self
end

function MobTracker:start()
	user_events.zone_change = windower.register_event('zone change', function(_, _)
		self.debuffed_mobs = {}
	end)

	user_events.action_message = windower.register_event('action message', function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		if not party_util.party_claimed(target_id) then
			return
		end

		-- Mob dead or debuff wears off
		if T{6,20,113,406,605,646}:contains(message_id) and self.debuffed_mobs[target_id] then
			self.debuffed_mobs:delete(target_id)
		elseif T{85,653,654}:contains(message_id) then
			--if self.debuffed_mobs[target_id] then
			--	self.debuffed_mobs[target_id][param_1] = nil
			--	if self.debuff_events['lose debuff'] ~= nil then
			--		self.debuff_events['lose debuff'](target_id, param_1)
			--	end
			--end
		elseif T{204,206}:contains(message_id) then
			if self.debuffed_mobs[target_id] then
				self.debuffed_mobs[target_id][param_1] = nil
				if self.debuff_events['lose debuff'] ~= nil then
					self.debuff_events['lose debuff'](target_id, param_1)
				end
			end
		end
	end)

	user_events.message = windower.register_event('action', function(act)
		if act.targets == nil or #act.targets == 0 then return end

		-- Monsters only
		if windower.ffxi.get_mob_by_id(act.targets[1].id).spawn_type ~= 16 then return end

		if not party_util.party_claimed(act.targets[1].id) then
			return
		end

		-- Debuff lands
		if act.category == 4 then
			if act.targets[1].actions[1].message == 2 or act.targets[1].actions[1].message == 252 then
				if T{23,24,25,230,231,232}:contains(act.param) then
					self:apply_dot(act.targets[1].id, act.param)
				elseif helixes:contains(act.param) then
					--apply_helix(act.targets[1].id, act.param)
				end
			elseif T{236,237,268,271}:contains(act.targets[1].actions[1].message) then
				local effect = act.targets[1].actions[1].param
				local target = act.targets[1].id
				local spell = act.param

				if not self.debuffed_mobs[target] then
					self.debuffed_mobs[target] = T{}
				end

				if debuffs[effect] and debuffs[effect]:contains(spell) then
					self.debuffed_mobs[target][effect] = spell
					self:notify_gain_debuff(target, effect)
				end
			-- ${actor}'s ${spell} has no effect on ${target}
			elseif T{75}:contains(act.targets[1].actions[1].message) then
				local target = act.targets[1].id
				local spell = act.param
				if spell == nil then return end

				local effect = spell_util.buff_id_for_spell(spell)
				if effect == nil then return end

				if not self.debuffed_mobs[target] then
					self.debuffed_mobs[target] = T{}
				end

				if debuffs[effect] and debuffs[effect]:contains(spell) then
					self.debuffed_mobs[target][effect] = spell
					self:notify_gain_debuff(target, effect)
				end
			elseif T{85}:contains(act.targets[1].actions[1].message) then
				local effect = act.targets[1].actions[1].param
				local target = act.targets[1].id
				local spell = act.param
				--if self.debuffed_mobs[target_id] then
				--self.debuffed_mobs[target_id][effect] = nil
					if self.debuff_events['lose debuff'] ~= nil then
						self.debuff_events['lose debuff'](target, effect)
					end
				--end
			end
		end
	end)
end

function MobTracker:apply_dot(target_id, spell_id)
	if not self.debuffed_mobs[target_id] then
		self.debuffed_mobs[target_id] = {}
	end

	local priority = 0
	local current = self.debuffed_mobs[target_id][134] or self.debuffed_mobs[target_id][135]
	if current then
		priority = hierarchy[current]
	end

	if hierarchy[spell_id] > priority then
		if T{23,24,25}:contains(spell_id) then
			self.debuffed_mobs[target_id][134] = spell_id
			self.debuffed_mobs[target_id][135] = nil
			self:notify_gain_debuff(target_id, 134)
		elseif T{230,231,232}:contains(spell_id) then
			self.debuffed_mobs[target_id][134] = nil
			self.debuffed_mobs[target_id][135] = spell_id
			self:notify_gain_debuff(target_id, 135)
		end
	end
end

function MobTracker:notify_gain_debuff(target_id, buff_id)
	if self.debuff_events['gain debuff'] ~= nil then
		self.debuff_events['gain debuff'](target_id, buff_id)
	end
end

function MobTracker:stop()
	if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
end

function MobTracker:register_event(event_name, event_handler)
	self.debuff_events[event_name] = event_handler
end

function MobTracker:unregister_event(event_name)
	self.debuff_events[event_name] = nil
end

-- Returns a table of status ids mapped to buff ids (e.g. blindness -> blind, but ids)
function MobTracker:debuffs_for_target(target_id)
	if self.debuffed_mobs[target_id] then
		return self.debuffed_mobs[target_id]
	end
	return T{}
end

return MobTracker



