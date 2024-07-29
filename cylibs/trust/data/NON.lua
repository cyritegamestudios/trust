local Trust = require('cylibs/trust/trust')
local NoneTrust = setmetatable({}, {__index = Trust })
NoneTrust.__index = NoneTrust

function NoneTrust.new(action_queue)
    local empty_settings = T {
        GambitSettings = {
            Gambits = L {},
            Default = L {},
        }
    }
    local self = setmetatable(Trust.new(action_queue, S{}, empty_settings), NoneTrust)
    return self
end

function NoneTrust:add_role(role)
    -- no-op
end

return NoneTrust



