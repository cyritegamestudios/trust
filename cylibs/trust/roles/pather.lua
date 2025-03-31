local Pather = setmetatable({}, {__index = Role })
Pather.__index = Pather
Pather.__class = "Pather"

local DisposeBag = require('cylibs/events/dispose_bag')
local Path = require('cylibs/paths/path')
local PathRecorder = require('cylibs/paths/path_recorder')
local PathTarget = require('cylibs/paths/path_target')
local player_util = require('cylibs/util/player_util')

-------
-- Default initializer for a pather role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam string path_dir Directory where paths are loaded and saved
-- @treturn Pather A pather role
function Pather.new(action_queue, path_dir, follower)
    local self = setmetatable(Role.new(action_queue), Pather)

    self.path_dir = path_dir
    self.follower = follower
    self.path_recorder = PathRecorder.new(self:get_path_dir())

    self.dispose_bag = DisposeBag.new()
    self.dispose_bag:addAny(L{ self.path_recorder })

    return self
end

function Pather:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Pather:on_add()
    Role.on_add(self)

    self.dispose_bag:add(self.follower:on_follow_target_changed():addAction(function(_, old_target, _)
        if self.path_target and self.path_target == old_target then
            self:stop(true)
        end
    end), self.follower:on_follow_target_changed())
end

-------
-- Starts or resumes execution of the current path, if any.
function Pather:start()
   self.follower:start_following()
end

-------
-- Stops execution of the current path, if any.
function Pather:stop(clear_path)
    if clear_path then
        self.path_target:destroy()
        self.path_target = nil

        self.follower:set_follow_target(nil)

        addon_system_message("Path cleared.")
    else
        self.follower:stop_following()

        addon_system_message("Path paused.")
    end
end

-------
-- Sets the current path.
-- @tparam Path Current path
function Pather:set_path(path)
    if path:get_zone_id() ~= windower.ffxi.get_info().zone then
        self:get_party():add_to_chat(self:get_party():get_player(), "I need to be in "..res.zones[path:get_zone_id()].en.." to do that!")
        return
    end
    if self.path_target and self.path_target:get_path():get_path_name() == path:get_path_name() then
        addon_system_error("Unable to start path while path is running. Use // trust path stop to clear the current path.")
        return
    end

    state.AutoFollowMode:set('Path')

    self.path_target = PathTarget.new(path)

    self.follower:set_follow_target(self.path_target)

    addon_system_message(string.format("Started path."))

    self.path_target:on_path_finish():addAction(function(_)
        self:stop(true)
    end)

    self.path_target.timer:onTimeChange():addAction(function()
        local position = self.path_target:get_position()

        local dist = math.floor(player_util.distance(player_util.get_player_position(), position))
        if dist < 1 then
            self.path_target.current_index = self.path_target.current_index + 1
        end
        self.path_target:set_position(position[1], position[2], position[3])
    end)
    self.path_target.timer:start()
end

function Pather:set_path_with_name(path_name, auto_reverse)
    local path = Path.from_file(self:get_path_dir()..path_name)
    if path then
        path:set_should_auto_reverse(auto_reverse)
        self:set_path(path)
    end
end

function Pather:get_path_dir()
    return self.path_dir
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