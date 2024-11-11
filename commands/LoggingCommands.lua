local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local LoggingTrustCommands = setmetatable({}, {__index = TrustCommands })
LoggingTrustCommands.__index = LoggingTrustCommands
LoggingTrustCommands.__class = "LoggingTrustCommands"

function LoggingTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), LoggingTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_toggle, 'Toggle debug logging')
    self:add_command('filter', self.handle_set_filter, 'Filter by logs containing the specified text', L{
        TextInputConfigItem.new('filter_pattern', '', 'Filter Pattern', function(_) return true  end)
    })
    self:add_command('all', self.handle_clear_filter, 'Clear filters and log everything')

    return self
end

function LoggingTrustCommands:get_command_name()
    return 'log'
end

function LoggingTrustCommands:handle_toggle()
    local success = true
    local message

    logger.isEnabled = not logger.isEnabled
    if logger.isEnabled then
        message = "Debug logging enabled"
    else
        message = "Debug logging disabled"
    end

    return success, message
end

-- // trust log filter filter_pattern
function LoggingTrustCommands:handle_set_filter(_, filter_pattern)
    local success = true
    local message = "Filtering by logs containing the text "..filter_pattern

    logger.filterPattern = filter_pattern

    return success, message
end

-- // trust log all
function LoggingTrustCommands:handle_clear_filter()
    local success = true
    local message = "Cleared all log filters"

    logger.filterPattern = nil

    return success, message
end

return LoggingTrustCommands