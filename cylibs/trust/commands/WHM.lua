local TrustCommands = require('cylibs/trust/commands/trust_commands')
local WhiteMageTrustCommands = setmetatable({}, {__index = TrustCommands })
WhiteMageTrustCommands.__index = WhiteMageTrustCommands
WhiteMageTrustCommands.__class = "WhiteMageTrustCommands"

function WhiteMageTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), WhiteMageTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('report', self.handle_report, 'Reports healer statistics')

    return self
end

function WhiteMageTrustCommands:get_command_name()
    return 'whm'
end

function WhiteMageTrustCommands:get_job()
    return self.trust:get_job()
end

function WhiteMageTrustCommands:handle_report()
    local success
    local message

    local healer = self.trust:role_with_type("healer")

    local tracker = healer:get_tracker()
    if tracker then
        success = true
        message = "Reporting healer statistics"

        tracker:report()
    else
        success = false
        message = "Healer tracker is not active"
    end
    return success, message
end

return WhiteMageTrustCommands