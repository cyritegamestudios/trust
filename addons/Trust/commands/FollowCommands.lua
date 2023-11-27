local TrustCommands = require('cylibs/trust/commands/trust_commands')
local FollowTrustCommands = setmetatable({}, {__index = TrustCommands })
FollowTrustCommands.__index = FollowTrustCommands
FollowTrustCommands.__class = "FollowTrustCommands"

function FollowTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), FollowTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_follow_party_member, 'Follow a player, // trust follow player_name')
    self:add_command('me', self.handle_follow_me, 'Make all players follow me')
    self:add_command('start', self.handle_start, 'Resume following')
    self:add_command('stopall', self.handle_stop_all, 'Pause following for all players')
    self:add_command('stop', self.handle_stop, 'Pause following')
    self:add_command('clear', self.handle_clear, 'Clear the follow target')
    self:add_command('distance', self.handle_set_follow_distance, 'Set the follow distance, // trust follow distance')

    return self
end

function FollowTrustCommands:get_command_name()
    return 'follow'
end

function FollowTrustCommands:get_follower()
    return self.trust:role_with_type("follower")
end

-- // trust follow me
function FollowTrustCommands:handle_follow_me()
    local success
    local message

    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        self:get_follower():set_follow_target(nil)
        IpcRelay.shared():send_message(CommandMessage.new('trust follow '..windower.ffxi.get_player().name))
        success = true
        message = 'Follow set to me on everyone else'
    else
        success = false
        message = 'IpcMode must be set to All or Send to use this command'
    end

    return success, message
end

-- // trust follow party_member_name
function FollowTrustCommands:handle_follow_party_member(party_member_name)
    local success
    local message

    if self:get_follower():is_valid_target(party_member_name) then
        handle_set('AutoFollowMode', 'Always')
        local error_message = self:get_follower():follow_target_named(party_member_name)
        if error_message then
            success = false
            message = error_message
        else
            success = true
            message = 'Now following '..party_member_name
        end
    else
        success = false
        message = party_member_name..' is not a valid party member'
    end

    return success, message
end

-- // trust follow distance number
function FollowTrustCommands:handle_set_follow_distance(distance)
    local success
    local message

    if distance:match("^%d+$") then
        distance = tonumber(distance)
        self:get_follower():set_distance(distance)
        success = true
        message = 'Follow distance set to '..distance
    else
        success = false
        message = 'Invalid distance '..distance
    end

    return success, message
end

-- // trust follow start
function FollowTrustCommands:handle_start()
    local success = true
    local message = 'Following resumed'

    self:get_follower():start_following()

    return success, message
end

-- // trust follow stop
function FollowTrustCommands:handle_stop()
    local success = true
    local message = 'Following paused'

    self:get_follower():stop_following()

    return success, message
end

-- // trust follow clear
function FollowTrustCommands:handle_clear()
    local success = true
    local message = 'Follow target cleared'

    self:get_follower():set_follow_target(nil)

    return success, message
end

-- // trust follow stopall
function FollowTrustCommands:handle_stop_all()
    local success
    local message

    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        IpcRelay.shared():send_message(CommandMessage.new('trust set AutoFollowMode Off'))
        success = true
        message = 'Follow disabled on everyone else'
    else
        success = false
        message = 'IpcMode must be set to All or Send to use this command'
    end

    return success, message
end

return FollowTrustCommands