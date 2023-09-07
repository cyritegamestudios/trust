---------------------------
-- Tracks buffs for all nearby players. If learning mode is enabled, it also creates a mapping of monster tp move
-- names to localized buff names. The output is saved to a file of the format monster_actions_PlayerName.lua in the
-- data folder for the addon containing this tracker.
-- @class module
-- @name MonsterBuffTracker

local files = require('files')
local party_util = require('cylibs/util/party_util')

local MonsterBuffTracker = {}
MonsterBuffTracker.__index = MonsterBuffTracker

monster_buff_action_message_ids = L{
    194 -- "${actor} uses ${weapon_skill}.${lb}${target} gains the effect of ${status}."
}

---- Event names for monster buffs. Used with register_event and unregister_event.
-- @table MonsterBuffEvent
-- @tfield string GainBuff Monster gains a buff
MonsterBuffEvent = {}
MonsterBuffEvent.GainBuff = 'gain_buff'

-------
-- Default initializer for a new monster buff tracker.
-- @treturn Monster Monster buff tracker
function MonsterBuffTracker.new()
    local self = setmetatable({
        user_events = {};
        buff_events ={};
        buffed_mobs = {};
        is_learning_enabled = false;
        monster_actions = {};
        monster_actions_file = nil;
    }, MonsterBuffTracker)
    return self
end

-------
-- Creates a new output file for the player if one does not already exist.
function MonsterBuffTracker:create_file_if_needed()
    self.monster_actions_file = files.new('data/monster_actions_'..windower.ffxi.get_player().name..'.lua')
    if self.monster_actions_file:exists() then
        windower.add_to_chat(2,'Monster Buff Tracker: Loading File: monster_actions_'..windower.ffxi.get_player().name..'.lua')
    else
        windower.add_to_chat(2,'Monster Buff Tracker: New File Created: monster_actions_'..windower.ffxi.get_player().name..'.lua')
        self.monster_actions = {}
        self.monster_actions_file:write('return ' .. T(self.monster_actions):tovstring())
    end
    self.monster_actions = require('data/monster_actions_'..windower.ffxi.get_player().name)
end

-------
-- Enables learning. When learning is enabled, a mapping of monster tp moves to buffs will be saved to a file of
-- the format monster_actions_PlayerName.lua in the data folder for the addon containing this tracker.
function MonsterBuffTracker:learn()
    if self.is_learning_enabled then return end

    self.is_learning_enabled = true

    self:create_file_if_needed()
end

function MonsterBuffTracker:gain_buff(target_id, resource, monster_ability_id, buff_id)
    local buff = res.buffs:with('id', buff_id)
    if buff == nil then return end

    local monster_ability = res[resource]:with('id', monster_ability_id)
    if monster_ability == nil then return end

    if self.buff_events['gain buff'] ~= nil then
        if party_util.party_claimed(target_id) then
            self.buff_events['gain buff'](target_id, buff.id)
        end
    end

    if not self.is_learning_enabled then return end

    if self.monster_actions[monster_ability.en] ~= nil then return end

    self.monster_actions[monster_ability.en] = self.monster_actions[monster_ability.en] or {}
    self.monster_actions[monster_ability.en]['Buff'] = buff.en

    self.monster_actions_file:write('return ' .. T(self.monster_actions):tovstring())

    windower.add_to_chat(2,'Monster Buff Tracker: Adding buff '..buff.en..' for ability '..monster_ability.en)
end

-------
-- Starts tracking monster buffs. Note that this function must be called before monster buffs will be recorded.
-- Before this object is disposed of, stop() should be called.
function MonsterBuffTracker:start()
    user_events.action_packet = ActionPacket.open_listener(function(act)
        local actionpacket = ActionPacket.new(act)
        local category = actionpacket:get_category_string()

        --if not categories:contains(category) or act.param == 0 then
        --    return
        --end

        local actor = actionpacket:get_id()
        local target = actionpacket:get_targets()()
        local action = target:get_actions()()
        local message_id = action:get_message_id()
        local add_effect = action:get_add_effect()
        --local basic_info = action:get_basic_info()
        local param, resource, action_id, interruption, conclusion = action:get_spell()

        if message_id == 194 then
            self:gain_buff(target.id, resource, action_id, param)
        end
    end)
end

-------
-- Stops tracking monster buffs and disposes of all registered event handlers.
function MonsterBuffTracker:stop()
    if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end
end

-------
-- Registers a new event handler.
-- @tparam MonsterBuffEvent event_name Event name to register a handler for
-- @tparam function event_handler Function to be called when the event is triggered
function MonsterBuffTracker:register_event(event_name, event_handler)
    self.buff_events[event_name] = event_handler
end

-------
-- Registers a new event handler.
-- @tparam MonsterBuffEvent event_name Event name to be unregistered
function MonsterBuffTracker:unregister_event(event_name)
    self.buff_events[event_name] = nil
end

return MonsterBuffTracker