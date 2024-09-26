local Eater = setmetatable({}, {__index = Role })
Eater.__index = Eater

state.AutoFoodMode = M{['description'] = 'Auto Food Mode', 'Off', 'Auto'}
state.AutoFoodMode:set_description('Auto', "Okay, I'll eat when I'm hungry.")

function Eater.new(action_queue, food_name)
    local self = setmetatable(Role.new(action_queue), Eater)

    self.action_queue = action_queue
    -- TODO: update when trust settings change
    self.food_name = food_name
    -- Checking item causes a huge memory footprint increase
    self.is_food_enabled = food_name ~= nil --and res.items:with('en', food_name) ~= nil
    self.last_check_food_time = os.time()

    return self
end

function Eater:destroy()
    Role.destroy(self)
end

function Eater:on_add()
    Role.on_add(self)
end

function Eater:target_change(target_index)
    Role.target_change(self, target_index)

    self:check_food()
end

function Eater:tic(new_time, old_time)
    Role.tic(new_time, old_time)
end

function Eater:check_food()
    if state.AutoFoodMode.value == 'Off' or not self.is_food_enabled or player.status == 'Idle'
            or (os.time() - self.last_check_food_time) < 15 then
        return
    end

    self.last_check_food_time = os.time()

    if not buff_util.is_food_active() then
        local food_action = SequenceAction.new(L{
            BlockAction.new(function() player_util.stop_moving()  end),
            CommandAction.new(0, 0, 0, '/item \"'..self.food_name..'\" <me>')
        }, 'eat_food')
        self.action_queue:push_action(food_action, true)
    end
end

function Eater:allows_duplicates()
    return false
end

function Eater:get_type()
    return "eater"
end

return Eater