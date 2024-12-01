---------------------------
-- Tracks the list of party targets.
-- @class module
-- @name MobTracker

local MobTracker = {}
MobTracker.__index = MobTracker
MobTracker.__class = "MobTracker"

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local logger = require('cylibs/logger/logger')
local Monster = require('cylibs/battle/monster')
local monster_util = require('cylibs/util/monster_util')
local packets = require('packets')

-- Event called when a mob is knocked out.
function MobTracker:on_mob_ko()
    return self.mob_ko
end

function MobTracker.new(on_party_member_added, on_party_member_removed)
    local self = setmetatable({
        player_ids = S{};
        mobs = T{};
        action_events = {};
        dispose_bag = DisposeBag.new();
    }, MobTracker)

    self.mob_ko = Event.newEvent()

    self.dispose_bag:add(on_party_member_added:addAction(function(t)
        self.dispose_bag:add(t:on_target_change():addAction(function(_, new_target_index, _)
            self:add_mob_by_index(new_target_index)
            self:prune_mobs()
        end), t:on_target_change())
        self:add_player(t:get_id())
    end), on_party_member_added)

    self.dispose_bag:add(on_party_member_removed:addAction(function(t)
        self:remove_player(t:get_id())
    end), on_party_member_removed)

    return self
end

function MobTracker:destroy()
    for _, event in pairs(self.action_events) do
        windower.unregister_event(event)
    end

    for mob in self:get_targets():it() do
        mob:destroy()
    end
    self.mobs = {}

    self.mob_ko:removeAllActions()

    self.dispose_bag:destroy()
end

function MobTracker:reset()
    for mob in self:get_targets():it() do
        mob:destroy()
    end
    self.mobs = {}
end

function MobTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if monster_util.is_monster(action.actor_id) then
            for _, target in pairs(action.targets) do
                if self.player_ids:contains(target.id) then
                    self:add_mob(action.actor_id)
                end
            end
        elseif self.player_ids:contains(action.actor_id) then
            for _, target in pairs(action.targets) do
                if monster_util.is_monster(target.id) then
                    self:add_mob(target.id)
                end
            end
        end
    end), WindowerEvents.Action)

    self.action_events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
        if id == 0x00E then
            local p = packets.parse('incoming', data)
            local status = res.statuses[p['Status']]
            if status and L{'Dead','Engaged', 'Engaged dead'}:contains(status.en) then
                local mob_id = monster_util.id_for_index(p['Index'])
                if mob_id then
                    local mob = self:get_mob(mob_id)
                    if mob and mob:get_mob().hpp <= 0 then
                        self:remove_mob(mob_id)
                    end
                end
            end
        end
    end)
    
    self.action_events.zone_change = windower.register_event('zone change', function(_, _)
        self:reset()
    end)
end

function MobTracker:is_valid_mob(target_id)
    if target_id == nil or not monster_util.is_monster(target_id) then
        return false
    end
    return true
end

-------
-- Starts tracking a mob.
-- @tparam number target_id Mob id
function MobTracker:add_mob(target_id)
    if not self:is_valid_mob(target_id) then
        return
    end
    local mob = self:get_mob(target_id)
    if mob then
        return
    end
    mob = Monster.new(target_id)
    mob:monitor()

    self.mobs[target_id] = mob

    logger.notice("Started tracking", mob:get_name(), mob:get_id(), target_id)
end

-------
-- Starts tracking a mob.
-- @tparam number target_index Mob index
function MobTracker:add_mob_by_index(target_index)
    self:add_mob(monster_util.id_for_index(target_index))
end

-------
-- Stops tracking a mob.
-- @tparam number target_id Mob id
function MobTracker:remove_mob(target_id)
    local mob = self:get_mob(target_id)
    if not mob then
        return
    end
    mob:destroy()

    self.mobs[target_id] = nil

    logger.notice("Stopped tracking", mob:get_name(), mob:get_id())
end

-------
-- Stops tracking mobs that are no longer targeted by the party.
function MobTracker:prune_mobs()
    local mob_ids_to_remove = L{}
    for id, mob in pairs(self.mobs) do
        print(mob:get_mob().claim_id)
        if not battle_util.is_valid_target(id) or mob:get_mob().claim_id == nil or not self.player_ids:contains(mob:get_mob().claim_id) or L{ 'Idle' }:contains(mob:get_status()) and mob:get_distance():sqrt() > 50 then
            mob_ids_to_remove:append(id)
        end
    end
    for mob_id in mob_ids_to_remove:it() do
        self:remove_mob(mob_id)
    end
end

function MobTracker:add_player(player_id)
    self.player_ids:add(player_id)
end

function MobTracker:remove_player(player_id)
    self.player_ids:remove(player_id)
end

-------
-- Returns the mob with the given target id.
-- @tparam number target_id Mob id
-- @treturn Monster Monster, or nil if the target is not being tracked
function MobTracker:get_mob(target_id)
    if target_id == nil then
        return nil
    end
    return self.mobs[target_id]
end

-------
-- Returns all mobs being tracked.
-- @treturn list List of Monsters being tracked
function MobTracker:get_targets()
    local targets = L{}
    for _, target in pairs(self.mobs) do
        targets:append(target)
    end
    return targets
end

return MobTracker

