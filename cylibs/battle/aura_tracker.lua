---------------------------
-- Determines enemy auras.
-- @class module
-- @name AuraTracker

require('tables')
require('lists')
require('logger')

local AuraTracker = {}
AuraTracker.__index = AuraTracker

-------
-- Default initializer for a new damage memory tracker.
-- @tparam list aura_debuff_names List of aura debuff names (see buffs.lua)
-- @tparam Party party Player's party
-- @treturn AuraTracker An aura tracker
function AuraTracker.new(aura_debuff_names, party)
    local self = setmetatable({
        action_events = {};
        aura_debuff_ids = aura_debuff_names:map(function(debuff_name) return res.buffs:with('en', debuff_name).id  end);
        party = party;
        status_effect_history = {};
        aura_probabilities = {};
    }, AuraTracker)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function AuraTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

-------
-- Call on every tic.
function AuraTracker:tic(_, _)
    for target_id, target_record in pairs(self.status_effect_history) do
        for debuff_id, _ in pairs(target_record) do
            print('checking '..debuff_id..' on '..target_id)
            local party_member = self.party:get_party_member(target_id)
            if party_member and party_member:has_debuff(debuff_id) then
                self:increment_aura_probability(debuff_id)
            else
                self:decrement_aura_probability(debuff_id)
            end
        end
    end
    self.status_effect_history = {}
end

-------
-- Resets the damage memory.
function AuraTracker:reset()
    self.status_effect_history = {}
    self.aura_probabilities = {}
end

-------
-- Records a status effect removal.
-- @tparam number spell_id Id of spell cast to remove status effect (see spells.lua)
-- @tparam number target_id Target of damage
-- @tparam number debuff_id Id of debuff (see buffs.lua)
function AuraTracker:record_status_effect_removal(spell_id, target_id, debuff_id)
    if not self.aura_debuff_ids:contains(debuff_id) then
        return
    end

    local party_member = self.party:get_party_member(target_id)
    if not party_member:has_debuff(debuff_id) then
        return
    end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if party_util.is_party_member(target.id) then
        local target_record = self.status_effect_history[target.id] or {}

        local debuff_record = target_record[debuff_id] or {}
        debuff_record.spell_id = spell_id

        target_record[debuff_id] = debuff_record

        self.status_effect_history[target_id] = target_record

        print('recording '..debuff_id..' on '..target_id)
    end
end

-------
-- Increments the probabilty that a debuff is caused by an aura.
-- @tparam number debuff_id Id of debuff (see buffs.lua)
function AuraTracker:increment_aura_probability(debuff_id)
    local current_probabilty = self.aura_probabilities[debuff_id] or 0

    self.aura_probabilities[debuff_id] = math.min(current_probabilty + 25, 100)

    print('current aura chance of '..debuff_id.. ' is '..self.aura_probabilities[debuff_id])
end

-------
-- Decrements the probabilty that a debuff is caused by an aura.
-- @tparam number debuff_id Id of debuff (see buffs.lua)
function AuraTracker:decrement_aura_probability(debuff_id)
    local current_probabilty = self.aura_probabilities[debuff_id] or 0

    self.aura_probabilities[debuff_id] = math.max(current_probabilty - 25, 0)

    print('current aura chance of '..debuff_id.. ' is '..self.aura_probabilities[debuff_id])
end

-------
-- Returns the probability that a debuff is causec by an aura.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn number The probability (%) that this debuff is caused by an aura
function AuraTracker:get_aura_probability(debuff_id)
    return self.aura_probabilities[debuff_id] or 0
end

return AuraTracker