local Follower = setmetatable({}, {__index = Role })
Follower.__index = Follower

local WalkAction = require('cylibs/actions/walk')

state.AutoFollowMode = M{['description'] = 'Auto Follow Mode', 'Off', 'Always'}

function Follower.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Follower)

    self.action_queue = action_queue
    self.walk_action_queue = ActionQueue.new(nil, false, 100, false, false)
    self.action_events = {}
    self.distance = 6
    self.maxfollowdistance = 35
    self.maxfollowpoints = 100
    self.keybind = 'f1'
    self.follow_mode = 'Auto'

    return self
end

function Follower:destroy()
    Role.destroy(self)

    if self.party_assist_target_change_id then
        self:get_party():on_party_assist_target_change():removeAction(self.party_assist_target_change_id)
    end

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function Follower:on_add()
    self.party_assist_target_change_id = self:get_party():on_party_assist_target_change():addAction(function(_, party_member)
        if party_member then
            self:follow_target(party_member:get_name())
        else
            self:stop_following()
        end
    end)

    self.action_events.postrender = windower.register_event('postrender', function()
        self:check_distance()
    end)

    self.action_events.status = windower.register_event('status change', function(new_status_id, old_status_id)
        self:on_player_status_change(new_status_id, old_status_id)
    end)
end

function Follower:follow_target(target_name)
    self:stop_following()

    target_name = target_name:gsub("^%l", string.upper)

    local player = windower.ffxi.get_player()
    if target_name == player.name or not self:check_target_in_range(target_name) then
        return "Invalid target %s":format(target_name)
    end

    self.walk_action_queue:enable()

    windower.ffxi.run(false)

    addon_message(207, 'Now following '..target_name..' with mode '..state.AutoFollowMode.current)
end

function Follower:stop_following()
    self.walk_action_queue:clear()
    self.walk_action_queue:disable()
end

function Follower:check_distance()
    if state.AutoFollowMode.value == 'Off' or self:get_follow_target() == nil or self:get_follow_target():get_mob() == nil then
        return
    end

    local follow_target = self:get_follow_target():get_mob()

    if self.walk_action_queue:last() == nil or self.walk_action_queue:last():distance(follow_target.x, follow_target.y, follow_target.z) > 1 then
        if math.abs(follow_target.z - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).z) > 1 or math.sqrt(follow_target.distance) > self.distance then
            self.walk_action_queue:push_action(WalkAction.new(follow_target.x, follow_target.y, follow_target.z, 2))
        end
    end
end

function Follower:check_target_in_range(target_name)
    local follow_target = windower.ffxi.get_mob_by_name(target_name)
    if follow_target then
        if follow_target.distance:sqrt() < self.maxfollowdistance then
            return true
        end
    end
    return false
end

function Follower:on_player_status_change(new_status_id, old_status_id)
    player.status = res.statuses[new_status_id].english

    if player.status == 'Dead' then
        self:stop_following()
    end

    if state.AutoFollowMode.value == 'Always' then
        local assist_target = self:get_follow_target()
        if assist_target and assist_target:get_name() == windower.ffxi.get_player().name then
            return
        end
        if player.status == 'Idle' then
            coroutine.sleep(1)
            if assist_target and assist_target:get_name() ~= windower.ffxi.get_player().name then
                self:follow_target(assist_target:get_name())
            end
        else
            self:stop_following()
        end
    end
end

function Follower:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
end

function Follower:tic(_, _)
end

function Follower:allows_duplicates()
    return false
end

function Follower:get_type()
    return "follower"
end

function Follower:get_follow_target()
    return self:get_party():get_assist_target()
end

return Follower