local Pather = setmetatable({}, {__index = Role })
Pather.__index = Pather
Pather.__class = "Pather"

require('queues')

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local ModeDelta = require('cylibs/modes/mode_delta')
local Path = require('cylibs/paths/path')
local PatherModes = require('cylibs/trust/data/modes/common/pather')
local PathRecorder = require('cylibs/paths/path_recorder')
local player_util = require('cylibs/util/player_util')

-- Event called when path replay starts.
function Pather:on_path_replay_start()
    return self.path_replay_start
end

-- Event called when path replay stops
function Pather:on_path_replay_stop()
    return self.path_replay_stop
end

-------
-- Default initializer for a pather role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam string path_dir Directory where paths are loaded and saved
-- @treturn Pather A pather role
function Pather.new(action_queue, path_dir)
    local self = setmetatable(Role.new(action_queue), Pather)

    self.current_index = 1
    self.path_dir = path_dir
    self.enabled = false
    self.is_reversed = false
    self.actions = L{}
    self.pather_delta = ModeDelta.new(PatherModes.Running)
    self.path_recorder = PathRecorder.new(self:get_path_dir())
    self.action_dispose_bag = DisposeBag.new()
    self.path_replay_start = Event.newEvent()
    self.path_replay_stop = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self.dispose_bag:addAny(L{ self.path_recorder })

    return self
end

function Pather:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()

    self.path_replay_start:removeAllEvents()
    self.path_replay_stop:removeAllEvents()
end

function Pather:on_add()
    Role.on_add(self)

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(a, _)
        if a == self.actions[self.current_index] then
            logger.notice(self.__class, 'completed', a:tostring())
            self.current_index = self.current_index + 1
            self:perform_next_action()
        end
    end), self.action_queue:on_action_end())
end

function Pather:target_change(target_index)
    Role.target_change(self, target_index)

    local target = self:get_target()
    if target then
        self:stop()
        self.pather_delta:remove()
    else
        self:start()
    end
end

function Pather:tic(_, _)
    if state.AutoPathMode == 'Off' then
        return
    end
end

-------
-- Starts or resumes execution of the current path, if any.
function Pather:start()
    if not self.path then
        return
    end
    self.enabled = true

    self:on_path_replay_start():trigger(self, self.path)

    self:perform_next_action()
end

-------
-- Stops execution of the current path, if any.
function Pather:stop()
    if not self.path then
        return
    end
    self.enabled = false

    self:on_path_replay_stop():trigger(self, self.path)
end

function Pather:perform_next_action()
    if not self:is_enabled() then
        return
    end

    local action = self:get_next_action()
    if action then
        local dist = math.floor(player_util.distance(player_util.get_player_position(), action:get_position()))
        if dist < 10 then
            logger.notice(self.__class, 'perform_next_action', 'current_index', self.current_index, action:tostring())

            self.pather_delta:apply()
            self.action_queue:push_action(action, true)
        else
            logger.notice(self.__class, 'perform_next_action', 'current_index', self.current_index, 'too far', action:tostring())

            self:get_party():add_to_chat(self:get_party():get_player(), "I can't do that, I'm "..dist.." yalms away from the closest point!")

            self:stop()
        end
    else
        self.pather_delta:remove()
    end
end

function Pather:get_next_action()
    local action
    if self.current_index > self.actions:length() then
        if self.path:should_reverse() then
            self.actions = self.path:get_actions():copy(true)

            self.is_reversed = not self.is_reversed
            if self.is_reversed then
                self.actions = self.actions:reverse()
            end
            self.current_index = 2
            action = self.actions[self.current_index]
        else
            self:stop()
        end
    else
        action = self.actions[self.current_index]
    end
    return action
end

-------
-- Sets the current path.
-- @tparam Path Current path
function Pather:set_path(path)
    self:stop()

    if path:get_zone_id() ~= windower.ffxi.get_info().zone then
        self:get_party():add_to_chat(self:get_party():get_player(), "I need to be in "..res.zones[path:get_zone_id()].en.." to do that!")
        return
    end

    self.path = path
    self.actions = self.path:get_actions():copy(true)

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

    logger.notice(self.__class, 'set_path', 'start_index', self.current_index)
end

function Pather:get_path_dir()
    return self.path_dir
end

function Pather:set_path_with_name(path_name, auto_reverse)
    local path = Path.from_file(self:get_path_dir()..path_name)
    if path then
        path:set_should_auto_reverse(auto_reverse)
        self:set_path(path)
    end
end

-------
-- Returns whether the pather is enabled.
-- @treturn boolean Whether the pather is enabled
function Pather:is_enabled()
    return self.path and self.enabled
end

-------
-- Sets whether the pather is enabled.
-- @tparam boolean enabled Whether the pather is enabled
function Pather:set_enabled(enabled)
    self.enabled = enabled
end

function Pather:allows_duplicates()
    return false
end

function Pather:get_type()
    return "pather"
end

function Pather:get_path_recorder()
    return self.path_recorder
end

return Pather