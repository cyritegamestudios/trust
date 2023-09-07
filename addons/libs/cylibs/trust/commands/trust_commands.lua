local TrustCommands = {}
TrustCommands.__index = TrustCommands

function TrustCommands.new()
    local self = setmetatable({

    }, TrustCommands)

    return self
end

function TrustCommands:handle_command(...)
end

return TrustCommands



