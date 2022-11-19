local Roller = setmetatable({}, {__index = Role })
Roller.__index = Roller

state.AutoRollMode = M{['description'] = 'Auto Roll Mode', 'Manual', 'Auto', 'Off'}

function Roller.new(action_queue, job, roll1_name, roll2_name, party)
    local self = setmetatable(Role.new(action_queue), Roller)

    self.action_queue = action_queue
    self.job = job
    self.should_double_up = false
    self.is_winning_streak_active = false
    self.roll1_name = roll1_name
    self.roll1_current = 0
    self.roll2_name = roll2_name
    self.roll2_current = 0
    self.last_roll_time = os.time()

    return self
end

function Roller:destroy()
    Role.destroy(self)

    self:get_player():on_job_ability_used():removeAction(self.job_ability_used_id)
end

function Roller:on_add()
    Role.on_add(self)

    self.job_ability_used_id = self:get_player():on_job_ability_used():addAction(
            function(_, job_ability_id, targets)
                if self.job:is_roll(job_ability_id) then
                    coroutine.schedule(function()
                        self:on_roll_used(job_ability_id, targets)
                    end, 1)
                end
            end)
end

function Roller:on_roll_used(roll_id, targets)
    should_double_up = false

    local roll_num = targets[1].actions[1].param

    local roll = res.job_abilities:with('id', roll_id)
    if roll.name == self.roll1_name then
        self.roll1_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
        end
        --print(self.roll1_name..' is currently at '..roll_num..' should double up '..tostring(self.should_double_up))
    elseif roll.name == self.roll2_name then
        self.roll2_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
        end
        --print(self.roll2_name..' is currently at '..roll_num..' should double up '..tostring(self.should_double_up))
    end
end

function Roller:target_change(target_index)
    Role.target_change(self, target_index)
end

function Roller:tic(new_time, old_time)
    Role.tic(new_time, old_time)

    self:check_rolls()
end

function Roller:check_rolls()
    if state.AutoRollMode.value == 'Off' or (not self.job:can_double_up() and (os.time() - self.last_roll_time) < 5) then
        return
    end

    last_roll_time = os.time()

    if self.job:busted() then
        self.job:fold()
        return
    end

    if self.job:can_double_up() and self.should_double_up or self.job:is_snake_eye_active() then
        self.job:double_up()
        return
    end

    if state.AutoRollMode.value == 'Auto' then
        if self.job:can_roll() then
            local roll1 = res.job_abilities:with('name', self.roll1_name)
            if not self.job:has_roll(roll1.id) then
                self.job:roll(roll1.id)
                return
            end
            local roll2 = res.job_abilities:with('name', self.roll2_name)
            if not self.job:has_roll(roll2.id) then
                self.job:roll(roll2.id)
                return
            end
        end
    end
end

function Roller:allows_duplicates()
    return false
end

function Roller:get_type()
    return "roller"
end

return Roller