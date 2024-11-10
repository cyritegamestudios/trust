local DismountAction = require('cylibs/actions/dismount')
local MountAction = require('cylibs/actions/mount')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MountCommands = setmetatable({}, {__index = TrustCommands })
MountCommands.__index = MountCommands
MountCommands.__class = "MountCommands"

function MountCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), MountCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.allowed_mounts = S(player_util.get_mounts())

    local mount_names = L{}
    for _, mount in pairs(res.mounts) do
        if self.allowed_mounts:contains(mount.en) then
            local description = "Calls forth a "..mount.en..", "
            self:add_command(mount.en, function(_)
                return self:handle_mount(mount.en)
            end, description..' // trust mount '..mount.en)
            mount_names:append(mount.en)
        end
    end

    self:add_command('default', function(mount_name)
        return self:handle_mount('Raptor')
    end, 'Calls forth a mount, // trust mount mount_name', L{
        PickerConfigItem.new('mount_name', mount_names[1], mount_names, nil, "Mount Name"),
    })

    self:add_command('random', self.handle_random_mount, 'Calls forth a random mount, // trust mount random')

    self:add_command('all', self.handle_mount_all, 'Calls forth a mount on all characters, // trust mount all mount_name', L{
        PickerConfigItem.new('mount_name', mount_names[1], mount_names, nil, "Mount Name"),
    })
    self:add_command('dismount', self.handle_dismount, 'Dismounts if mounted, // trust mount dismount all', L{
        PickerConfigItem.new('all', '', L{ '', 'all' }, function(value)
            if value == 'all' then
                return 'Party'
            else
                return 'Self'
            end
        end, "Dismount Target"),
    })

    return self
end

function MountCommands:get_command_name()
    return 'mount'
end

-- // trust mount mount_name include_party
function MountCommands:handle_mount(mount_name, include_party)
    local success
    local message

    mount_name = (mount_name or ""):gsub("(%a)(%w*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

    local mount = res.mounts:with('en', mount_name)

    if self.allowed_mounts:contains(mount.en:lower()) then
        success = false
        message = "Invalid mount"
        return success, message
    end

    local mount_id = mount.id

    if S{ 5, 85 }:contains(windower.ffxi.get_player().status) then
        success = false
        message = "You are already riding a mount"
    else
        success = true
        if include_party then
            message = "Mounting "..mount_name.." on all characters"
            IpcRelay.shared():send_message(CommandMessage.new('trust mount '..mount.en))
        else
            message = "Mounting"
        end
        self.action_queue:push_action(MountAction.new(mount_id), true)
    end

    return success, message
end

-- // trust mount random
function MountCommands:handle_random_mount()
    local success
    local message

    if self.allowed_mounts:length() > 0 then
        local mount_index = math.ceil(math.random() * self.allowed_mounts:length())
        success, message = self:handle_mount(L(self.allowed_mounts)[mount_index])
    else
        success = false
        message = "You have not learned any mounts"
    end

    return success, message
end

-- // trust mount all [mount_name]
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