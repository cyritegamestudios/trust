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

-- Hoisted out of the per-packet 0x00E handler below: building this List on
-- every NPC update (the most frequent incoming packet) just to test
-- membership. :contains() never mutates the list, so sharing one is exact.
local dead_or_engaged_statuses = L{'Dead', 'Engaged', 'Engaged dead'}

-- Hoisted out of prune_mobs() below: same reason, one List per mob per prune.
local idle_statuses = L{ 'Idle' }

-- Safely compute a distance magnitude from whatever get_distance() returned.
-- get_distance() may return a number, a V{} vector, a plain table, or nil.
-- Never throws: returns nil when the value cannot be read as a distance.
local function distance_magnitude(dist)
    if type(dist) == 'number' then
        return dist
    end
    if not dist or type(dist) ~= 'table' then
        return nil
    end
    if dist.sqrt then
        local ok, val = pcall(function() return dist:sqrt() end)
        if ok and type(val) == 'number' then
            return val
        end
    end
    local x = dist[1] or dist.x or 0
    local y = dist[2] or dist.y or 0
    local z = dist[3] or dist.z or 0
    if type(x) == 'number' and type(y) == 'number' and type(z) == 'number' then
        return math.sqrt(x * x + y * y + z * z)
    end
    return nil
end

-- Event called when a mob is knocked out.
function MobTracker:on_mob_ko()
    return self.mob_ko
end

-- Event called when targets are added or removed.
function MobTracker:on_targets_changed()
    return self.targets_changed
end

function MobTracker.new(on_party_member_added, on_party_member_removed, party_target)
    local self = setmetatable({
        player_ids = S{};
        mobs = T{};
        action_events = {};
        party_target = party_target;
        dispose_bag = DisposeBag.new();
        member_dispose_bags = {};
    }, MobTracker)

    self.mob_ko = Event.newEvent()
    self.targets_changed = Event.newEvent()

    self.dispose_bag:add(on_party_member_added:addAction(function(t)
        -- Per-member dispose bag (same pattern as SongTracker): the
        -- target_change registration must be removed when the member
        -- leaves, not held in the tracker-level bag until destroy.
        -- PartyMember objects are discarded on removal, so each add
        -- used to leave one stale event + closure in the tracker-level
        -- bag for the rest of the session (one per Trust summon/dismiss).
        local member_id = t:get_id()
        local member_dispose_bag = self.member_dispose_bags[member_id]
        if member_dispose_bag then
            member_dispose_bag:destroy()
        end
        member_dispose_bag = DisposeBag.new()
        self.member_dispose_bags[member_id] = member_dispose_bag

        member_dispose_bag:add(t:on_target_change():addAction(function(_, new_target_index, _)
            self:add_mob_by_index(new_target_index)
            self:prune_mobs()
        end), t:on_target_change())
        self:add_player(member_id)
        self:add_mob_by_index(t:get_target_index())
    end), on_party_member_added)

    self.dispose_bag:add(on_party_member_removed:addAction(function(t)
        local member_dispose_bag = self.member_dispose_bags[t:get_id()]
        if member_dispose_bag then
            member_dispose_bag:destroy()
            self.member_dispose_bags[t:get_id()] = nil
        end
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

    for _, member_dispose_bag in pairs(self.member_dispose_bags) do
        member_dispose_bag:destroy()
    end
    self.member_dispose_bags = {}

    self.mob_ko:removeAllActions()
    self.targets_changed:removeAllActions()

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
        if action.targets == nil then return end
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
            if status and dead_or_engaged_statuses:contains(status.en) then
                local mob_id = monster_util.id_for_index(p['Index'])
                if mob_id then
                    local mob = self:get_mob(mob_id)
                    local m = mob and mob:get_mob()
                    if mob and m and m.hpp <= 0 then
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
        -- Mob ids are recycled: a new mob can spawn on a dead mob's id.
        -- Entity stores the name seen at creation, so if the live mob's
        -- name differs, the old mob's tracker state must not carry over.
        local current_mob = windower.ffxi.get_mob_by_id(target_id)
        if not current_mob or mob:get_name() == current_mob.name then
            return
        end
        self:remove_mob(target_id)
    end
    mob = Monster.new(target_id)
    mob:monitor()

    self.mobs[target_id] = mob

    self:on_targets_changed():trigger(self, L{ mob }, L{})

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

    self:on_targets_changed():trigger(self, L{}, L{ mob })

    logger.notice("Stopped tracking", mob:get_name(), mob:get_id())
end

-------
-- Stops tracking mobs that are no longer targeted by the party.
function MobTracker:prune_mobs()
    -- party_target() is a pure read; call it once, not once per Idle mob.
    local party_target_index = self.party_target():get_target_index()
    local mob_ids_to_remove = L{}
    for id, mob in pairs(self.mobs) do
        -- get_mob() was called up to 3 times per mob here (claim_id twice,
        -- .index once), one windower.ffxi.get_mob_by_id FFI call each.
        -- Read it once. A nil mob means it left memory, which
        -- is_valid_target() would also report as invalid, so it is pruned
        -- instead of crashing on nil.claim_id as the old code did.
        local mob_info = mob:get_mob()
        local mob_dist = distance_magnitude(mob:get_distance())
        if mob_info == nil or not battle_util.is_valid_target(id) or (mob_info.claim_id ~= nil and mob_info.claim_id ~= 0 and not self.player_ids:contains(mob_info.claim_id))
                or (idle_statuses:contains(mob:get_status()) and party_target_index ~= mob_info.index) or (mob_dist ~= nil and mob_dist > 50) then
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

