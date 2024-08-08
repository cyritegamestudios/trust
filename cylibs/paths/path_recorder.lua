local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local FileIO = require('files')
local Path = require('cylibs/paths/path')
local serializer_util = require('cylibs/util/serializer_util')
local WalkAction = require('cylibs/actions/walk')

local PathRecorder = {}
PathRecorder.__index = PathRecorder
PathRecorder.__class = "PathRecorder"

-- Event called when path recording starts.
function PathRecorder:on_path_record_start()
    return self.path_record_start
end

-- Event called when path recording stops
function PathRecorder:on_path_record_stop()
    return self.path_record_stop
end

function PathRecorder.new(output_folder, mob_id)
    local self = setmetatable({}, PathRecorder)

    self.output_folder = output_folder
    self.mob_id = mob_id or windower.ffxi.get_player().id
    self.recording = false
    self.actions = L{}
    self.path_record_start = Event.newEvent()
    self.path_record_stop = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    return self
end

function PathRecorder:destroy()
    self.path_record_start:removeAllActions()
    self.path_record_stop:removeAllActions()

    self.dispose_bag:destroy()
end

function PathRecorder:clear()
    self.actions = L{}
end

function PathRecorder:start_recording()
    if self:is_recording() then
        return
    end
    self.recording = true

    self:on_path_record_start():trigger(self)

    self.dispose_bag:add(WindowerEvents.PositionChanged:addAction(function(mob_id, x, y, z)
        if mob_id == self.mob_id then
            self:add_point(x, y, z)
        end
    end), WindowerEvents.PositionChanged)

    logger.notice(self.__class, 'start_recording')
end

function PathRecorder:stop_recording(path_name, discard)
    if not self:is_recording() then
        return nil
    end
    self.recording = false

    self:on_path_record_stop():trigger(self, path_name, discard)

    if discard then
        self:clear()
        return nil
    end

    if path_name == nil then
        path_name = res.zones[windower.ffxi.get_info().zone].en
    end

    if path_name then
        local path = Path.new(windower.ffxi.get_info().zone, self.actions, false, 0)
        if path then
            local file_path = self.output_folder..path_name..'.lua'

            local file = FileIO.new(file_path)
            file:write('\nreturn ' .. serializer_util.serialize(path))

            logger.notice(self.__class, 'stop_recording', 'saved path to', windower.addon_path..file_path)

            return file_path
        end
    end
    return nil
end

function PathRecorder:add_point(x, y, z)
    self.actions:append(WalkAction.new(x, y, z, 1))
end

function PathRecorder:get_actions()
    return self.actions
end

function PathRecorder:is_recording()
    return self.recording
end

function PathRecorder:get_output_folder()
    return self.output_folder
end

return PathRecorder



