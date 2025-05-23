---------------------------
-- Utility functions for healing magic.
-- @class module
-- @name CureUtil

_libs = _libs or {}

local Buff = require('cylibs/battle/spells/buff')
local res = require('resources')

local cure_util = {}

_raw = _raw or {}

_libs.cure_util = cure_util

local debuff_to_spell = {
	['sleep'] = 'Cure',
	['Accuracy Down'] = 'Erase',
	['addle'] = 'Erase',
	['AGI Down'] = 'Erase',
	['Attack Down'] = 'Erase',
	['bind'] = 'Erase',
	['Bio'] = 'Erase',
	['blindness'] = 'Blindna',
	['Burn'] = 'Erase',
	['Choke'] = 'Erase',
	['CHR Down'] = 'Erase',
	['curse'] = 'Cursna',
	['Defense Down'] = 'Erase',
	['DEX Down'] = 'Erase',
	['Dia'] = 'Erase',
	['disease'] = 'Viruna',
	['doom'] = 'Cursna',
	['doomed'] = 'Cursna',
	['Drown'] = 'Erase',
	['Elegy'] = 'Erase',
	['Evasion Down'] = 'Erase',
	['Frost'] = 'Erase',
	['Inhibit TP'] = 'Erase',
	['INT Down'] = 'Erase',
	['Lullaby'] = 'Cure',
	['Magic Acc. Down'] = 'Erase',
	['Magic Atk. Down'] = 'Erase',
	['Magic Def. Down'] = 'Erase',
	['Magic Evasion Down'] = 'Erase',
	['Max HP Down'] = 'Erase',
	['Max MP Down'] = 'Erase',
	['Max TP Down'] = 'Erase',
	['MND Down'] = 'Erase',
	['Nocturne'] = 'Erase',
	['paralysis'] = 'Paralyna',
	['petrification'] = 'Stona',
	['plague'] = 'Viruna',
	['poison'] = 'Poisona',
	['Rasp'] = 'Erase',
	['Requiem'] = 'Erase',
	['Shock'] = 'Erase',
	['silence'] = 'Silena',
	['slow'] = 'Erase',
	['STR Down'] = 'Erase',
	['VIT Down'] = 'Erase',
	['weight'] = 'Erase',
	['Flash'] = 'Erase',
	['KO'] = 'Raise'
}

-- Default cure settings if none are specified
cure_util.default_cure_settings = {
	Magic = {
		Thresholds = {
			['Cure IV'] = 1500,
			['Cure III'] = 600,
			['Cure II'] = 0,
			['Curaga III'] = 900,
			['Curaga II'] = 600,
			['Curaga'] = 0
		},
		Delay = 2,
		StatusRemovals = {
			Delay = 3,
			Blacklist = L{
			}
		}
	},
	Waltz = {
		Thresholds = {
			Emergency = 40,
			Default = 78,
			["Curing Waltz II"] = 0,
			["Curing Waltz III"] = 600,
			["Curing Waltz IV"] = 1500,
			["Divine Waltz"] = 0,
			["Divine Waltz II"] = 600,
		},
		Delay = 2,
		StatusRemovals = {
			Delay = 3,
			Blacklist = L{

			}
		}
	},
}

-------
-- Determines the spell that can remove a debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn number Spell id for the spell that can remove the debuff, or nil if none exists
function cure_util.spell_id_for_debuff_id(debuff_id)
	local debuff = res.buffs:with('id', debuff_id)
	if debuff then
		if debuff_id == 0 then
			for spell_name in L{ 'Arise', 'Raise III', 'Raise II', 'Raise' }:it() do
				local spell = res.spells:with('en', spell_name)
				if spell and spell_util.can_cast_spell(spell.id) then
					return spell.id
				end
			end
		else
			local spell_name = debuff_to_spell[debuff.en]
			if spell_name then
				local spell = res.spells:with('en', spell_name)
				if spell then
					return spell.id
				end
			end
		end
	end
	return nil
end

-------
-- Determines the priority of a cure.
-- @tparam number hpp Cure target's current hit point percentage
-- @tparam Boolean is_trust Whether the cure is being applied to a trust
-- @tparam Boolean is_aoe Whether the cure is AOE
-- @treturn ActionPriority Action priority, to be used with an action
function cure_util.get_cure_priority(hpp, is_trust, is_aoe)
	if not is_aoe then
		if hpp <= 0 then
			return ActionPriority.High
		elseif hpp < 20 then
			if not is_trust then
				return ActionPriority.highest
			else
				return ActionPriority.high
			end
		elseif hpp < 40 then
			return ActionPriority.high
		elseif hpp < 60 then
			return ActionPriority.medium
		else
			return ActionPriority.default
		end
	else
		if hpp < 75 then
			return ActionPriority.high
		else
			return ActionPriority.medium
		end
	end
end

-------
-- Determines the priority of a status removal.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam Boolean is_trust Whether the status removal is being applied to a trust
-- @treturn ActionPriority Action priority, to be used with an action
function cure_util.get_status_removal_priority(debuff_id, is_trust)
	if L{'doom','curse','petrification','sleep'}:contains(buff_util.buff_name(debuff_id)) then
		if not is_trust then
			return ActionPriority.highest
		else
			return ActionPriority.high
		end
	else
		return ActionPriority.medium
	end
end

return cure_util