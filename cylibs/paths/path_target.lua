local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local Timer = require('cylibs/util/timers/timer')

local PathTarget = setmetatable({}, {__index = Entity })
PathTarget.__index = PathTarget
PathTarget.__type = "PathTarget"

-- Event called when the party member's position changes.
function PathTarget:on_position_change()
    return self.position_change
end

-- Event called when the party member's zone changes. Only works when IpcMode is not set to Off.
function PathTarget:on_zone_change()
    return self.zone_change
end

function PathTarget:on_path_finish()
    return self.path_finish
end

function PathTarget.new(path)
    local self = setmetatable(Entity.new(0), PathTarget)

    self.path = path
    self.name = "Path"
    self.position = V{0, 0, 0}
    self.actions = self.path:get_actions():copy(true)
    self.timer = Timer.scheduledTimer(0.05)

    local current_index = 1
    local min_dist = 9999
    for i = 1, self.actions:length() do
        local action = self.actions[i]
        local dist = player_util.distance(player_util.get_player_position(), action:get_position())
        if dist < min_dist then
            min_dist = dist
            current_index = i
        end
    end
    self.current_index = current_index

    self.position_change = Event.newEvent()
    self.zone_change = Event.newEvent()
    self.path_finish = Event.newEvent()

    return self
end

function PathTarget:destroy()
    self.timer:destroy()

    self.position_change:removeAllActions()
    self.zone_change:removeAllActions()
    self.path_finish:removeAllActions()
end

function PathTarget:get_name()
    return "Path"
end

function PathTarget:get_mob()
    return {
        name = self.name,
        distance = 10,
        hpp = 100
    }
end

-------
-- Sets the (x, y, z) coordinate of the mob.
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @tparam number z Z coordinate
function PathTarget:set_position(x, y, z)
    local last_position = self:get_position()
    if last_position[1] == x and last_position[2] == y and last_position[3] == z then
        return
    end
    Entity.set_position(self, x, y, z)

    self:on_position_change():trigger(self, x, y,  z)
end

function PathTarget:get_position()
    local action
    if self.current_index > self.actions:length() then
        if self.path:should_reverse() then
            self:on_path_finish():trigger(self, true)

            self.actions = self.path:get_actions():copy(true)

            self.is_reversed = not self.is_reversed
            if self.is_reversed then
                self.actions = self.actions:reverse()
            end
            self.current_index = 2
            action = self.actions[self.current_index]
        else
            self:on_path_finish():trigger(self)
            return V{0, 0, 0}
        end
    else
        action = self.actions[self.current_index]
    end
    return action:get_position()
end

function PathTarget:get_zone_id()
    return self.path:get_zone_id()
end

function PathTarget:get_path()
    return self.path
end

return PathTarget