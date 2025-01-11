local Role = {}
Role.__index = Role

function Role.new(action_queue)
    local self = setmetatable({
        action_queue = action_queue;
        target_index = nil;
        last_tic_time = os.time();
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

function Role:allows_duplicates()
    return false
end

function Role:get_type()
    return "role"
end

function Role:get_localized_name()
    return self:get_type()
end

function Role:set_player(player)
    self.player = player
end

function Role:get_player()
    return self.player
end

function Role:set_alliance(alliance)
    self.alliance = alliance
end

function Role:get_alliance()
    return self.alliance
end

function Role:set_party(party)
    self.party = party
end

function Role:get_party()
    return self.party
end

function Role:set_job(job)
    self.job = job
end

function Role:get_job()
    return self.job
end

function Role:get_target()
    if self.target_index then
        return self:get_alliance():get_target_by_index(self.target_index)
    end
    return nil
end

function Role:set_last_tic_time(last_tic_time)
    self.last_tic_time = last_tic_time
end

function Role:get_last_tic_time()
    return self.last_tic_time
end

function Role:tostring()
    return nil
end

return Role