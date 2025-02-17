---------------------------
-- Wrapper around monster metadata with additional functionality.
-- @class module
-- @name Monster

local DebuffTracker = require('cylibs/battle/trackers/debuff_tracker')
local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local res = require('resources')
local action_message_util = require('cylibs/util/action_message_util')
local buff_util = require('cylibs/util/buff_util')
local CumulativeMagicTracker = require('cylibs/battle/trackers/cumulative_magic_tracker')
local logger = require('cylibs/logger/logger')
local monster_abilities_ext = require('cylibs/res/monster_abilities')
local monster_util = require('cylibs/util/monster_util')
local monster_families = require('cylibs/res/monster_families')
local monsters = require('cylibs/res/monsters')
local ResistTracker = require('cylibs/battle/resist_tracker')
local spell_util = require('cylibs/util/spell_util')
local StepTracker = require('cylibs/battle/trackers/step_tracker')

local Monster = setmetatable({}, {__index = Entity })
Monster.__index = Monster
Monster.__class = "Monster"

-- Event called when the monster's target changes.
function Monster:on_target_change()
    return self.target_change
end

-- Event called when the monster finishes a tp move.
function Monster:on_tp_move_finish()
    return self.tp_move_finish
end

-- Event called when the monster gains a buff.
function Monster:on_gain_buff()
    return self.gain_buff
end

-- Event called when the monster loses a buff.
function Monster:on_lose_buff()
    return self.lose_buff
end

-- Event called when the monster gains a debuff.
function Monster:on_gain_debuff()
    return self.debuff_tracker:on_gain_debuff()
end

function Monster:on_spell_resisted()
    return self.spell_resisted
end

-- Event called when the monster starts casting a spell.
function Monster:on_spell_begin()
    return self.spell_begin
end

-- Event called when a monster's spell finishes casting.
function Monster:on_spell_finish()
    return self.spell_finish
end

-- Event called when a skillchain is made on the monster
function Monster:on_skillchain()
    return self.skillchain
end

-- Event called when a skillchain on the monster ends
function Monster:on_skillchain_ended()
    return self.skillchain_ended
end

num_monsters = 0

-------
-- Default initializer for a new monster.
-- @tparam number mob_id Mob id
-- @treturn Monster A monster
function Monster.new(mob_id)
    local self = setmetatable(Entity.new(mob_id), Monster)

    self.mob_id = mob_id
    self.current_target = nil
    self.buff_ids = S{}
    self.resistances = T{}

    local mob = windower.ffxi.get_mob_by_id(self.mob_id)
    if mob then
        local monster = monsters[mob.models[1]]
        if monster then
            self.family = monster.family
            self.type = monster.type
            local family = monster_families:with('family', monster.family)
            if family then
                self.resistances = family.resistances
            end
        end
    end

    self.target_change = Event.newEvent()
    self.tp_move_finish = Event.newEvent()
    self.gain_buff = Event.newEvent()
    self.lose_buff = Event.newEvent()
    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()
    self.spell_resisted = Event.newEvent()
    self.spell_begin = Event.newEvent()
    self.spell_finish = Event.newEvent()
    self.skillchain = Event.newEvent()
    self.skillchain_ended = Event.newEvent()

    self.dispose_bag = DisposeBag.new()

    num_monsters = num_monsters + 1

    return self
end

-------
-- Creates a new Monster by index
-- @tparam number mob_index Mob index
-- @treturn Monster A monster
function Monster.get_by_index(mob_index)
    local mob_id = monster_util.id_for_index(mob_index)
    if monster_util.is_monster(mob_id) then
        return Monster.new(mob_id)
    end
    return nil
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Monster:destroy()
    if self.is_destroyed then
        return
    end
    self.is_destroyed = true

    self.target_change:removeAllActions()
    self.tp_move_finish:removeAllActions()
    self.gain_buff:removeAllActions()
    self.lose_buff:removeAllActions()
    self.gain_debuff:removeAllActions()
    self.lose_debuff:removeAllActions()
    self.spell_resisted:removeAllActions()
    self.spell_begin:removeAllActions()
    self.spell_finish:removeAllActions()
    self.skillchain:removeAllActions()
    self.skillchain_ended:removeAllActions()

    self.dispose_bag:destroy()

    num_monsters = num_monsters - 1
end

-------
-- Starts tracking the monster's actions. Note that it is necessary to call this before functions like get_current_target().
-- Before this object is disposed of, stop_tracking() should be called.
function Monster:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.debuff_tracker = DebuffTracker.new(self:get_id())
    self.debuff_tracker:monitor()

    self.cumulative_magic_tracker = CumulativeMagicTracker.new(self:get_id())
    self.cumulative_magic_tracker:monitor()

    self.step_tracker = StepTracker.new(self:get_id(), self.debuff_tracker)
    self.step_tracker:monitor()

    self.resist_tracker = ResistTracker.new(self:get_id(), self:on_spell_resisted())

    self.dispose_bag:addAny(L{ self.debuff_tracker, self.step_tracker, self.resist_tracker, self.cumulative_magic_tracker })

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        if act.actor_id == self.mob_id then
            self:handle_action_by_monster(act)
        else
            self:handle_action_on_monster(act)
        end
    end), WindowerEvents.Action)

    self.dispose_bag:add(WindowerEvents.Ability.Finish:addAction(function(target_id, ability_id)
        if not ability_id then
            return
        end
        local ability = monster_abilities_ext[ability_id]
        if ability then
            self:handle_gain_buff(ability.status)
        end
    end), WindowerEvents.Ability.Finish)
end

function Monster:handle_action_by_monster(act)
    -- Mighty guard is category 11 and param 2667
    if action_message_util.is_finish_tp_move_category(act.category) then
        for _, target in pairs(act.targets) do
            local action = target.actions[1]
            if action then
                -- ${actor} uses ${weapon_skill}.${lb}${target} takes ${number} points of damage.
                if L{ 185, 186, 187, 188 }:contains(action.message) then
                    local monster_ability = res.monster_abilities:with('id', act.param) or {id=-999,en="Unknown",ja="Unknown"}
                    local monster_ability_name = monster_ability.en
                    self:on_tp_move_finish():trigger(self, monster_ability_name, windower.ffxi.get_mob_by_id(target.id).name, action.param)
                end
            end
        end
    end

    local target = windower.ffxi.get_mob_by_id(act.targets[1].id)
    if target and target.id and target.id ~= self.mob_id then
        -- I think mighty guard is going into this case
        if self.current_target == nil or target.id ~= self.current_target.id then
            self:on_target_change():trigger(self, target.index)
        end
        self.current_target = target
    end

    if action_message_util.is_finish_action_category(act.category) then
        local action = act.targets[1].actions[1]
        if action_message_util.is_monster_gain_buff(action.message, action.param) then
            self:handle_gain_buff(action.param)
        elseif action_message_util.is_spell_finish_message(action.message, act.param) then
            self:on_spell_finish():trigger(self, target.index, act.param)
        end
    end
end

function Monster:handle_action_on_monster(act)
    for _, target in pairs(act.targets) do
        if target.id == self.mob_id then
            local action = target.actions[1]
            if action then
                if action_message_util.is_spikes_message(action.message) then
                    -- Note: since we don't know the source of the spikes, we are just using the id for Ice Spikes
                    self:handle_gain_buff(35)
                -- resist: 85, 284 (AOE)
                -- completely resist: 655, 656 (AOE)
                -- immunobreak: 653, 654
                elseif action_message_util.is_monster_lose_buff(action.message) then
                    self:handle_lose_buff(action.param)
                elseif action_message_util.is_lose_multiple_buffs(action.message) then -- 792 is probably what we want
                    local num_buffs = action.param
                    local buff_ids_to_remove = L(self:get_buff_ids()):slice(1, math.min(num_buffs, self:get_buff_ids():length()))
                    for buff_id in buff_ids_to_remove:it() do
                        self:handle_lose_buff(buff_id)
                    end
                elseif action_message_util.is_spell_no_effect_message(action.message) then
                    if L{260, 360}:contains(act.param) then -- Dispel
                        self:reset_buffs()
                    end
                elseif L{85, 284}:contains(action.message) then -- regular resist spell
                    local spell_name = spell_util.spell_name(act.param)
                    if spell_name then
                        self:on_spell_resisted():trigger(self, spell_name, false)
                    end
                elseif L{655}:contains(action.message) then
                    local spell_name = spell_util.spell_name(act.param)
                    if spell_name then
                        self:on_spell_resisted():trigger(self, spell_name, true)
                    end
                end
            end
        end
    end
end

function Monster:reset_buffs()
    logger.notice("Resetting all buffs for", self:get_name())
    for buff_id in self.buff_ids:copy(true):it() do
        self:handle_lose_buff(buff_id)
    end
end

function Monster:handle_gain_buff(buff_id)
    if not self.buff_ids:contains(buff_id) then
        self.buff_ids:add(buff_id)
        self:on_gain_buff():trigger(self, self:get_mob().index, buff_id)

        logger.notice(self:get_name(), "gains the effect of", (res.buffs[buff_id] and res.buffs[buff_id].name) or 'unknown', self:get_buffs())
    end
end

function Monster:handle_lose_buff(buff_id)
    if self.buff_ids:contains(buff_id) then
        self.buff_ids:remove(buff_id)
        self:on_lose_buff():trigger(self, self:get_mob().index, buff_id)

        logger.notice(self:get_name(), "loses the effect of", (res.buffs[buff_id] and res.buffs[buff_id].name) or 'unknown', self:get_buffs())
    end
end

-------
-- Returns a list of the monster's buffs.
-- @treturn List of buff ids (see buffs.lua)
function Monster:get_buff_ids()
    return self.buff_ids
end

-------
-- Returns a list of the monster's buffs.
-- @treturn List of localized buff names (see buffs.lua)
function Monster:get_buffs()
    return L(self.buff_ids:map(function(buff_id)
        return res.buffs[buff_id].enl
    end))
end

-------
-- Returns true if the monster has the given debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn boolean True if the monster has the given debuff, false otherwise
function Monster:has_debuff(debuff_id)
    return self.debuff_tracker:has_debuff(debuff_id)
end

-------
-- Returns the list of active debuff ids.
-- @treturn list List of debuff ids (see res/buffs.lua)
function Monster:get_debuff_ids()
    return self.debuff_tracker:get_debuff_ids()
end

-------
-- Returns the current cumulative magic effect.
-- @treturn CumulativeMagicEffect Cumulative magic effect, or nil if none
function Monster:get_cumulative_effect()
    return self.cumulative_magic_tracker:get_current_effect()
end

-------
-- Returns the monster's resist tracker.
-- @treturn ResistTracker Resist tracker
function Monster:get_resist_tracker()
    return self.resist_tracker
end

-------
-- Returns the monster's step tracker.
-- @treturn StepTracker Step tracker
function Monster:get_step_tracker()
    return self.step_tracker
end

-------
-- Returns the current target of the monster.
-- @treturn MobMetadata Returns the full metadata for the monster's target, or nil if the monster isn't targeting anyone
function Monster:get_current_target()
    return self.current_target
end

-------
-- Returns whether the monster is party claimed.
-- @treturn boolean True if the monster is party claimed
function Monster:is_claimed()
    return party_util.party_claimed(self:get_id())
end

-------
-- Returns whether the monster is claimed by any member in an alliance.
-- @tparam Alliance alliance The alliance
-- @treturn boolean True if the monster is alliance claimed
function Monster:is_claimed_by(alliance)
    return alliance:is_claimed(self:get_id())
end

-------
-- Returns the localized status of the monster.
-- @treturn string Status of the monster (see res/statuses.lua)
function Monster:get_status()
    local mob = self:get_mob()
    if mob then
        return res.statuses[mob.status].en
    end
    return 'Idle'
end

function Monster:get_hpp()
    return self:get_mob().hpp
end

-------
-- Sets the current skillchain active on this monster.
-- @tparam SkillchainStep skillchain Active skillchain
function Monster:set_skillchain(skillchain_step)
    logger.notice(self.__class, 'set_skillchain', skillchain_step and tostring(skillchain_step) or 'none')
    self.skillchain_step = skillchain_step
    if self.skillchain_step then
        self:on_skillchain():trigger(self, skillchain_step)
    else
        self:on_skillchain_ended():trigger(self)
    end
end

-------
-- Returns the current skillchain active on this monster, if any.
-- @treturn SkillchainStep Active skillchain, or nil if no skillchain is active
function Monster:get_skillchain()
    return self.skillchain_step
end

function Monster:has_resistance_info()
    return L(T(self.resistances):keyset()):length() > 0
end

function Monster:get_resistance(element_id)
    return self.resistances[element_id] or 1
end

-------
-- Return a description of the monster.
-- @treturn string Description
function Monster:description()
    local result = self:get_name()..', HP: '..self:get_mob().hpp..'%'
    if self:get_mob().claim_id and windower.ffxi.get_mob_by_id(self:get_mob().claim_id) then
        result = result..', Claimed By: '..windower.ffxi.get_mob_by_id(self:get_mob().claim_id).name
    end
    return result
end

function Monster:__eq(otherItem)
    if otherItem == nil then
        return false
    end
    return self:get_id() == otherItem:get_id()
end

return Monster