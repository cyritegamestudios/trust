local localization_util = require('cylibs/util/localization_util')

local Action = require('cylibs/actions/action')
local LoadGlobalsAction = setmetatable({}, { __index = Action })
LoadGlobalsAction.__index = LoadGlobalsAction

function LoadGlobalsAction.new()
    local self = setmetatable(Action.new(0, 0, 0), LoadGlobalsAction)
    return self
end

function LoadGlobalsAction:perform()
    state.TrustMode = M{['description'] = 'Trust Mode', T{}}

    state.AutoEnableMode = M{['description'] = 'Auto Enable Mode', 'Off', 'Auto'}
    state.AutoEnableMode:set_description('Auto', "Okay, I'll automatically get to work after the addon loads.")

    state.AutoDisableMode = M{['description'] = 'Auto Disable Mode', 'Auto', 'Off'}
    state.AutoDisableMode:set_description('Auto', "Okay, I'll automatically disable Trust after zoning.")

    state.AutoUnloadOnDeathMode = M{['description'] = 'Auto Unload On Death Mode', 'Auto', 'Off'}
    state.AutoUnloadOnDeathMode:set_description('Off', "Okay, I'll pause Trust after getting knocked out but won't unload it. DO NOT USE WHILE AFK!")
    state.AutoUnloadOnDeathMode:set_description('Auto', "Okay, I'll automatically unload Trust after getting knocked out.")

    state.AutoBuffMode = M{['description'] = 'Buff Self and Party', 'Off', 'Auto'}
    state.AutoBuffMode:set_description('Auto', "Okay, I'll automatically buff myself and the party.")

    state.AutoEnmityReductionMode = M{['description'] = 'Auto Enmity Reduction Mode', 'Off', 'Auto'}
    state.AutoEnmityReductionMode:set_description('Auto', "Okay, I'll automatically try to reduce my enmity.")

    self:complete(true)
end

function LoadGlobalsAction:gettype()
    return "loadglobalsaction"
end

function LoadGlobalsAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadGlobalsAction:tostring()
    return "Loading globals"
end

return LoadGlobalsAction




