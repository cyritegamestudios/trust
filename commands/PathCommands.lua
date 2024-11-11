local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local PathTrustCommands = setmetatable({}, {__index = TrustCommands })
PathTrustCommands.__index = PathTrustCommands
PathTrustCommands.__class = "PathTrustCommands"

local DisposeBag = require('cylibs/events/dispose_bag')
local Path = require('cylibs/paths/path')
local PathRecorder = require('cylibs/paths/path_recorder')

function PathTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), PathTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.path_recorder = PathRecorder.new('data/paths/')
    self.dispose_bag = DisposeBag.new()

    self:add_command('record', self.handle_record_path, 'Start recording a path or discard the current path')
    self:add_command('save', self.handle_save_path, 'Save a recorded path, // trust path save path_name', L{
        TextInputConfigItem.new('path_name', '', 'Path Name', function(_) return true  end)
    })
    self:add_command('start', self.handle_start_path, 'Loads and starts a saved path, // trust path start path_name reverse', L{
        TextInputConfigItem.new('path_name', '', 'Path Name', function(_) return true  end),
        PickerConfigItem.new('reverse', false, L{ true, false }, nil, "Reverse")
    })
    self:add_command('stop', self.handle_stop_path, 'Stops the current path')

    self.dispose_bag:addAny(L{ self.path_recorder })

    return self
end

function PathTrustCommands:destroy()
    self.dispose_bag:destroy()
end

function PathTrustCommands:get_command_name()
    return 'path'
end

function PathTrustCommands:get_pather()
    return self.trust:role_with_type("pather")
end

-- // trust path record
function PathTrustCommands:handle_record_path()
    local success
    local message

    if self.path_recorder:is_recording() then
        self.path_recorder:stop_recording()

        success = true
        message = "Discarded the current recording"
    else
        self.path_recorder:start_recording()

        success = true
        message = "Started recording the player's actions"
    end

    return success, message
end

-- // trust path save path_name
function PathTrustCommands:handle_save_path(_, path_name)
    local success
    local message

    if path_name == nil or path_name:empty() then
        success = false
        message = "Invalid path name "..(path_name or 'nil')
    elseif self.path_recorder:is_recording() then
        path_name = path_name..'_'..windower.ffxi.get_player().name

        self.path_recorder:stop_recording(path_name)

        success = true
        message = "Path saved to "..self.path_recorder:get_output_folder()..path_name..'.lua'
    else
        success = false
        message = "Not recording a path, use // trust path record"
    end

    return success, message
end

-- // trust path start path_name reverse
function PathTrustCommands:handle_start_path(_, path_name, reverse)
    local success
    local message

    if path_name == nil or path_name:empty() then
        success = false
        message = "Invalid path name "..(path_name or 'nil')
    else
        path_name = path_name..'_'..windower.ffxi.get_player().name
        local path = Path.from_file(self.path_recorder:get_output_folder()..path_name..'.lua')
        if path then
            if path:get_zone_id() ~= windower.ffxi.get_info().zone then
                success = false
                message = path_name..' is only usable in '..res.zones[path:get_zone_id()].name
            else
                success = true
                message = "Starting path "..path_name

                if reverse then
                    path = path:reverse()
                end

                self:get_pather():set_path(path)
                self:get_pather():start()
            end
        else
            success = false
            message = "Invalid path name "..path_name
        end
    end

    return success, message
end

-- // trust path stop
function PathTrustCommands:handle_stop_path()
    local success
    local message

    self:get_pather():stop()

    success = true
    message = 'Stopped the current path'

    return success, message
end

return PathTrustCommands