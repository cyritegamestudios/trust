local Nuker = setmetatable({}, {__index = Role })
Nuker.__index = Nuker

function Nuker.new(action_queue, magic_burst_cooldown, magic_burst_mpp)
    local self = setmetatable(Role.new(action_queue), Nuker)
    self.magic_burst_cooldown = magic_burst_cooldown or 2
    self.magic_burst_mpp = magic_burst_mpp or 20
    self.last_magic_burst = os.time()
    return self
end

function Nuker:target_change(target_index)
    Role.target_change(self, target_index)
end

function Nuker:tic(new_time, old_time)
end

function Nuker:job_magic_burst(target_id, spell)
    if state.AutoMagicBurstMode.value == 'Off' or windower.ffxi.get_player().vitals.mpp < self.magic_burst_mpp then
        return
    end

    if os.time() - self.last_magic_burst > self.magic_burst_cooldown then
        self.last_magic_burst = os.time()

        self.action_queue:push_action(SpellAction.new(0, 0, 0, spell.id, self.target_index, self:get_player()))
    end
end

function Nuker:allows_duplicates()
    return false
end

function Nuker:get_type()
    return "nuker"
end

return Nuker