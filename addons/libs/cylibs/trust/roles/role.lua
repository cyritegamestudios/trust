local Role = {}
Role.__index = Role

function Role.new(action_queue)
    local self = setmetatable({
        action_queue = action_queue;
        target_index = nil;
    }, Role)

    return self
end

function Role:destroy()
end

function Role:on_add()
end

function Role:target_change(target_index)
    self.target_index = target_index
end

function Role:tic(new_time, old_time)
end

function Role:check_debuffs()
end

function Role:allows_duplicates()
    return false
end

function Role:get_type()
    return "role"
end

function Role:set_player(player)
    self.player = player
end

function Role:get_player()
    return self.player
end

function Role:set_party(party)
    self.party = party
end

function Role:get_party()
    return self.party
end

function Role:tostring()
    return nil
end

return Role