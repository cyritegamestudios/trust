local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')


require('logger')

local TrustReactions = {}
TrustReactions.__index = TrustReactions
TrustReactions.__type = "TrustReactions"

--state.TrustReactionsMode = M{['description'] = 'Trust Reactions Mode', 'Auto', 'Off'}
--state.TrustReactionsMode:set_description('Auto', "Okay, I'll react in real time to changing battle conditions.")

function TrustReactions.new(jobNameShort)
    local self = setmetatable({}, TrustReactions)

    self.jobNameShort = jobNameShort
    self.disposeBag = DisposeBag.new()

    self.reactions = require('data/reactions/'..jobNameShort)
    if not self.reactions then
        addon_message(207, 'Unable to load reactions for '..self.jobNameShort)
    end

    return self
end

function TrustReactions:loadReactions()
    local settings = self.reactions:getSettings()
    for modeName, reactions in pairs(settings.OnModeChange) do
        local stateVar = get_state(modeName)
        if stateVar then
            self.disposeBag:add(stateVar:on_state_change():addAction(function(s, newValue)
                local onModeValueChange = reactions[newValue]
                if onModeValueChange ~= nil then
                    onModeValueChange()
                end
            end), stateVar:on_state_change())
        end
    end
end

return TrustReactions