local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')

local Roller = setmetatable({}, {__index = Role })
Roller.__index = Roller

state.AutoRollMode = M{['description'] = 'Use Phantom Roll', 'Manual', 'Auto', 'Safe', 'Off'}
state.AutoRollMode:set_description('Manual', "Okay, you do the first roll and I'll double up on my own.")
state.AutoRollMode:set_description('Auto', "Okay, I'll roll on my own and chase 11s or lucky rolls.")
state.AutoRollMode:set_description('Safe', "Okay, I'll roll on my own and try not to bust.")

-- Event called when rolls begin
function Roller:on_rolls_begin()
    return self.rolls_begin
end

-- Event called when rolls end
function Roller:on_rolls_end()
    return self.rolls_end
end

function Roller.new(action_queue, job, roll1, roll2, party)
    local self = setmetatable(Role.new(action_queue), Roller)

    self.action_queue = action_queue
    self.job = job
    self.should_double_up = false
    self.is_xi_streak_active = false
    self.roll1 = roll1
    self.roll1_current = 0
    self.roll2 = roll2
    self.roll2_current = 0
    self.last_roll_time = os.time()
    self.is_rolling = false
    self.rolls_begin = Event.newEvent()
    self.rolls_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    return self
end

function Roller:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()

    self:on_rolls_begin():removeAllActions()
    self:on_rolls_end():removeAllActions()
end

function Roller:on_add()
    Role.on_add(self)

    self.dispose_bag:add(self:get_player():on_job_ability_used():addAction(
            function(_, job_ability_id, targets)
                if self.job:is_roll(job_ability_id) then
                    coroutine.schedule(function()
                        self:on_roll_used(job_ability_id, targets)
                    end, 1)
                end
            end), self:get_player():on_job_ability_used())

    self.dispose_bag:add(self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
        if buff_id == 309 then -- Busted
            self:set_is_rolling(false)
        end
    end), self:get_party():get_player():on_gain_buff())

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        if act.actor_id == self:get_player():get_id() then
            for _, target in pairs(act.targets) do
                for action in L(target.actions):it() do
                    if action.message == 426 then -- Busted
                        self:set_is_rolling(false)
                    end
                end
            end
        end
    end), WindowerEvents.Action)

    self.dispose_bag:add(state.AutoRollMode:on_state_change():addAction(function(_, newValue)
        if L{'Off', 'Manual'}:contains(newValue) then
            self:set_is_rolling(false)
        end
    end), state.AutoRollMode:on_state_change())
end

function Roller:on_roll_used(roll_id, targets)
    self.should_double_up = false

    local roll_num = targets[1].actions[1].param

    local roll = res.job_abilities:with('id', roll_id)
    if roll.en == self.roll1:get_roll_name() or state.AutoRollMode.value == 'Manual' then
        self.roll1_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
            if not self.should_double_up then
                self:set_is_rolling(false)
            end
        end
    elseif roll.en == self.roll2:get_roll_name() then
        self.roll2_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
            if not self.should_double_up then
                self:set_is_rolling(false)
            end
        end
    end
end

function Roller:target_change(target_index)
    Role.target_change(self, target_index)
end

function Roller:tic(new_time, old_time)
    Role.tic(new_time, old_time)

    self:check_rolls()
end

function Roller:set_is_rolling(is_rolling)
    if self.is_rolling == is_rolling then
        return
    end
    self.is_rolling = is_rolling
    if self.is_rolling then
        self:on_rolls_begin():trigger(self)
    else
        self:on_rolls_end():trigger(self)
    end
end

function Roller:get_is_rolling()
    return self.is_rolling
end

function Roller:check_rolls()
    if state.AutoRollMode.value == 'Off' or (not self.job:can_double_up() and (os.time() - self.last_roll_time) < 5) then
        return
    end

    self.last_roll_time = os.time()

    if self.job:busted() and self.job:can_fold() then
        self.job:fold()
        self:set_is_rolling(false)
        return
    end
    
    if self.job:can_double_up() and self.should_double_up or self.job:is_snake_eye_active() then
        self.job:double_up()
        return
    end

    if state.AutoRollMode.value == 'Auto' or state.AutoRollMode.value == 'Safe' then
        if self.job:can_roll() then
            local roll1 = res.job_abilities:with('en', self.roll1:get_roll_name())
            if not self.job:has_roll(roll1.id) then
                self:set_is_rolling(true)
                self.job:roll(roll1.id, self.roll1:should_use_crooked_cards())
                return
            end
            local roll2 = res.job_abilities:with('en', self.roll2:get_roll_name())
            if not self.job:has_roll(roll2.id) then
                self:set_is_rolling(true)
                self.job:roll(roll2.id, self.roll2:should_use_crooked_cards())
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

function Roller:set_rolls(roll1, roll2)
    self.roll1 = roll1
    self.roll2 = roll2
end

return Roller