local Follower = setmetatable({}, {__index = Role })
Follower.__index = Follower
Follower.__class = "Follower"

local BlockAction = require('cylibs/actions/block')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local logger = require('cylibs/logger/logger')
local player_util = require('cylibs/util/player_util')
local res = require('resources')
local RunToLocation = require('cylibs/actions/runtolocation')
local SequenceAction = require('cylibs/actions/sequence')
local WaitAction = require('cylibs/actions/wait')
local zone_util = require('cylibs/util/zone_util')

state.AutoFollowMode = M{['description'] = 'Follow', 'Off', 'Always', 'Path'}
state.AutoFollowMode:set_description('Always', "Follow the party member set with // trust follow when not in battle.")

-- Event called when the follow target changes
function Follower:on_follow_target_changed()
    return self.follow_target_changed
end

function Follower.new(action_queue, follow_distance, addon_settings, state_var)
    local self = setmetatable(Role.new(action_queue), Follower)

    self.action_queue = action_queue
    self.addon_settings = addon_settings
    self.state_var = state_var or state.AutoFollowMode
    self.walk_action_queue = ActionQueue.new(nil, false, 100, false, false)
    self.action_events = {}
    self.distance = follow_distance or 1
    self.auto_pause = addon_settings:getSettings().follow.auto_pause or false
    self.maxfollowdistance = 35
    self.maxfollowpoints = 100
    self.following = false
    self.max_zone_distance = 1
    self.zone_cooldown = 5
    self.last_position = vector.zero(3)
    -- self.last_zone_time = os.time() - self.zone_cooldown
    self.follow_target_changed = Event.newEvent()
    self.follow_target_dispose_bag = DisposeBag.new()
    self.dispose_bag = DisposeBag.new()

    return self
end

function Follower:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    self.dispose_bag:destroy()

    self.follow_target_changed:removeAllActions()

    self:stop_following()
end

function Follower:on_add()
    self.dispose_bag:add(self.state_var:on_state_change():addAction(function(_, new_value)
        if self.state_var.value == 'Off' then
            self:stop_following()
        end
    end), self.state_var:on_state_change())

    self.dispose_bag:add(self:get_party():get_player():on_status_change():addAction(function(_, new_status, old_status)
        if new_status == 'Idle' and L{ 'Dead', 'Engaged' }:contains(old_status) then
            self:start_following(true)
        end
    end), self:get_party():get_player():on_status_change())

    self.dispose_bag:add(self:get_party():on_party_assist_target_change():addAction(function(_, assist_target)
        if self:get_follow_target() == nil and assist_target then
            self:follow_target_named(assist_target:get_name())
        end
    end), self:get_party():on_party_assist_target_change())

    self.dispose_bag:add(self:get_party():get_player():on_zone_change():addAction(function(p, zone_id, x, y, z, zone_line, zone_type)
        self:start_following()
    end), self:get_party():get_player():on_zone_change())

    self.dispose_bag:add(self.addon_settings:onSettingsChanged():addAction(function(settings)
        self.distance = settings.follow.distance or 1
        self.auto_pause = settings.follow.auto_pause or false
    end, self.addon_settings:onSettingsChanged()))

    self.action_events.status = windower.register_event('status change', function(new_status_id, old_status_id)
        self:on_player_status_change(new_status_id, old_status_id)
    end)

    self.dispose_bag:add(self.action_queue:on_action_start():addAction(function(_, action)
        if self.auto_pause then
            self:stop_following()
        end
    end), self.action_queue:on_action_end())

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(a, success)
        if self.auto_pause then
            self:start_following()
        end
    end), self.action_queue:on_action_end())

    self.action_events.zone_change = windower.register_event('zone change', function(_, _)
        self.walk_action_queue:clear()
    end)
end

-------
-- Follows the target with the given name.
-- @tparam string target_name Name of the target
-- @treturn string Error message, or nil if there is none
function Follower:follow_target_named(target_name)
    target_name = target_name:gsub("^%l", string.upper)

    local target = self:get_alliance():get_alliance_member_named(target_name)
    if target == nil or not self:is_valid_target(target_name) then
        logger.error("Invalid target", target_name, target == nil, not self:is_valid_target(target_name))
        return "Invalid target %s":format(target_name)
    end
    self:set_follow_target(target)

    self:start_following()

    self:get_party():add_to_chat(self:get_party():get_player(), "Okay, I'll follow "..target_name.." when I'm not in battle.")
end

function Follower:start_following(override)
    if not override and S{ 'Dead', 'Engaged', 'Resting' }:contains(self:get_party():get_player():get_status()) then
        return
    end
    self.walk_action_queue:clear()
    self.walk_action_queue:enable()
    windower.ffxi.run(false)

    self:check_distance()
end

function Follower:stop_following(keep_queue)
    if not keep_queue then
        self.walk_action_queue:clear()
    end
    self.walk_action_queue:disable()
    windower.ffxi.run(false)
end

-------
-- Checks whether the target can be followed.
-- @tparam string target_name Name of the target
-- @treturn boolean True if the target can be followed
function Follower:is_valid_target(target_name)
    local target = self:get_alliance():get_alliance_member_named(target_name, true)
    if target == nil or target:get_mob() == nil or target:get_name() == windower.ffxi.get_player().name or target:get_zone_id() ~= windower.ffxi.get_info().zone then
        return false
    end
    if not IpcRelay.shared():is_connected(target_name) then
        for condition in self:get_conditions():it() do
            if not condition:is_satisfied(target:get_mob().index) then
                return false
            end
        end
    end
    return true
end

function Follower:check_distance()
    if self.state_var.value == 'Off' then
        return
    end
    local follow_target = self:get_follow_target()
    if follow_target == nil or state.AutoFollowMode.value == 'Always' and not self:is_valid_target(follow_target:get_name()) then
        if follow_target then
            self:get_party():add_to_chat(self.party:get_player(), "I can't find you. Whatever happened to no Trust left behind?", 'follower_follow_failure', 30)
        end
        return
    end

    local x = follow_target:get_position()[1]
    local y = follow_target:get_position()[2]
    local z = follow_target:get_position()[3]

    local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
    if player then
        local distance = player_util.distance(player_util.get_player_position(), follow_target:get_position())
        if distance < self.maxfollowdistance and (math.abs(z - player.z) > 1 or distance > self:get_distance()) then
            self.walk_action_queue:push_action(RunToLocation.new(x, y, z, self:get_distance()))
        end
    end
end

function Follower:on_player_status_change(new_status_id, old_status_id)
    player.status = res.statuses[new_status_id].english

    if S{ 'Dead', 'Engaged', 'Resting' }:contains(player.status) then
        self:stop_following()
        return
    end

    if self.state_var.value == 'Always' then
        if player.status == 'Idle' then
            self:start_following()
        end
    end
end

function Follower:tic(_, _)
end

function Follower:allows_duplicates()
    return false
end

function Follower:get_type()
    return "follower"
end

function Follower:get_distance()
    if state.AutoFollowMode.value == 'Path' then
        return 1
    else
        return self.distance
    end
end

function Follower:get_conditions()
    if state.AutoFollowMode.value == 'Path' then
        return L{}
    else
        return L{
            MaxDistanceCondition.new(self.maxfollowdistance),
            ValidTargetCondition.new(),
        }
    end
end

function Follower:set_follow_target(target)
    self:stop_following()

    -- Before moving this line check pather
    self:on_follow_target_changed():trigger(self, self.follow_target, target)

    self.follow_target = target
    self.follow_target_dispose_bag:destroy()

    if self.follow_target then
        self.follow_target_dispose_bag:add(self.follow_target:on_position_change():addAction(function(_, x, y, z)
            self:check_distance()
        end), self.follow_target:on_position_change())
        self.follow_target_dispose_bag:add(self.follow_target:on_zone_change():addAction(function(p, zone_id, x, y, z, zone_line, zone_type)
            if zone_util.is_valid_zone_request(zone_line, zone_type) then
                self:zone(zone_id, x, y, z, zone_line, zone_type)
            end
        end), self.follow_target:on_zone_change())
    else
        self.state_var:set('Off')
    end
end

function Follower:can_zone(zone_id)
    local player = self:get_party():get_player()
    if not player or (os.time() - player:get_last_zone_time()) < self.zone_cooldown
            or zone_id ~= windower.ffxi.get_info().zone or windower.ffxi.get_info().zone == 0 then
        return false
    end
    return true
end

function Follower:zone(zone_id, x, y, z, zone_line, zone_type, num_attempts)
    num_attempts = num_attempts or 0

    logger.notice(self.__class, "zone", '('..x..', '..y..', '..z..')', zone_line, zone_type, num_attempts)

    if num_attempts > 10 or not self:can_zone(zone_id) then
        logger.notice(self.__class, "zone", "error", res.zones[zone_id].en, zone_line, zone_type, num_attempts)
        return
    end
    self.walk_action_queue:clear()

    local actions = L{}

    local pos = V{x, y, z}
    local distance_to_zone = player_util.distance(player_util.get_player_position(), pos)
    if distance_to_zone < self.max_zone_distance and self:can_zone(zone_id) then
        logger.notice("Current distance to zone line: ", distance_to_zone)
        
        actions:append(WaitAction.new(x, y, z, 1 + math.random()))
        
        logger.notice("Attemping to zone from", res.zones[zone_id].en, zone_line, zone_type)
        local zone_action = BlockAction.new(function()
            if self:can_zone(zone_id) then
                zone_util.zone(zone_id, zone_line, zone_type)
            end
        end, 'follower_zone_request', 'Zoning')

        actions:append(zone_action)
    elseif distance_to_zone < 25 then
        actions:append(RunToLocation.new(x, y, z, self.max_zone_distance))

        local zone_retry_action = BlockAction.new(function()
            self:zone(zone_id, x, y, z, zone_line, zone_type, num_attempts + 1)
        end, 'follower_zone_request_retry', 'Zoning Retry')

        actions:append(zone_retry_action)
    else
        logger.notice(self.__class, "zone", "error", "too far from zone", res.zones[zone_id].en, zone_line, zone_type, distance_to_zone)
    end

    if actions:length() > 0 then
        self.walk_action_queue:push_action(SequenceAction.new(actions, 'follower_zone_'..num_attempts), true)
    end
end

function Follower:get_follow_target()
    return self.follow_target
end

function Follower:set_distance(distance)
    self.distance = distance
end

return Follower