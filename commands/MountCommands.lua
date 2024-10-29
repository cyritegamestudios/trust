local DismountAction = require('cylibs/actions/dismount')
local MountAction = require('cylibs/actions/mount')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MountCommands = setmetatable({}, {__index = TrustCommands })
MountCommands.__index = MountCommands
MountCommands.__class = "MountCommands"

function MountCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), MountCommands)

    self.trust = trust
    self.action_queue = action_queue

    local mount_names = L{}
    for _, mount in pairs(res.mounts) do
        local description = "Calls forth a "..mount.en..", "
        self:add_command(mount.en, function(_)
            return self:handle_mount(mount.en)
        end, description..' // trust mount '..mount.en)
        mount_names:append(mount.en)
    end

    self:add_command('default', function(mount_name)
        return self:handle_mount('Raptor')
    end, 'Mount, // trust mount mount_name')

    self:add_command('all', self.handle_mount_all, 'Calls forth a mount on all characters, // trust mount all [mount_name]')
    self:add_command('dismount', self.handle_dismount, 'Dismounts if mounted, // trust mount dismount [all]')

    return self
end

function MountCommands:get_command_name()
    return 'mount'
end

-- // trust mount mount_name include_party
function MountCommands:handle_mount(mount_name, include_party)
    local success
    local message

    local mount = res.mounts:with('en', mount_name)
    if mount == nil then
        success = false
        message = "Invalid mount"
        return
    end

    local mount_id = mount.id

    if S{ 5, 85 }:contains(windower.ffxi.get_player().status) then
        success = false
        message = "You are already riding a mount"
    else
        success = true
        if include_party then
            message = "Mounting on all characters"
            IpcRelay.shared():send_message(CommandMessage.new('trust mount '..mount.en))
        else
            message = "Mounting"
        end
        self.action_queue:push_action(MountAction.new(mount_id), true)
    end

    return success, message
end

-- // trust mount all mount_name
function MountCommands:handle_mount_all(_, ...)
    local mount_name = table.concat({...}, " ") or ""
    if mount_name == nil or mount_name:empty() then
        mount_name = 'Raptor'
    end
    return self:handle_mount(mount_name, true)
end

-- // trust mount dismount [all]
function MountCommands:handle_dismount(_, include_party)
    local success = false
    local message = "You are not riding a mount"

    if S{ 5, 85 }:contains(windower.ffxi.get_player().status) then
        success = true
        message = "Dismounting"
        self.action_queue:push_action(DismountAction.new(), true)
    end

    if include_party and include_party == 'all' then
        success = true
        message = "Dismounting on all characters"
        IpcRelay.shared():send_message(CommandMessage.new('trust mount dismount'))
    end

    return success, message
end

return MountCommands