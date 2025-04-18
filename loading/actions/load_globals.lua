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
    state.AutoEnableMode:set_description('Off', "Disable Trust after the addon loads.")
    state.AutoEnableMode:set_description('Auto', "Automatically start Trust after the addon loads.")

    state.AutoDisableMode = M{['description'] = 'Auto Disable Mode', 'Auto', 'Off'}
    state.AutoDisableMode:set_description('Off', "Do not disable Trust after zoning.")
    state.AutoDisableMode:set_description('Auto', "Disable Trust after zoning.")

    state.AutoUnloadOnDeathMode = M{['description'] = 'Auto Unload On Death Mode', 'Auto', 'Disable', 'Off'}
    state.AutoUnloadOnDeathMode:set_description('Off', "Keep trust on after getting knocked out. BEWARE USING WHILE AFK!")
    state.AutoUnloadOnDeathMode:set_description('Disable', "Pause Trust after getting knocked out.")
    state.AutoUnloadOnDeathMode:set_description('Auto', "Unload Trust after getting knocked out.")

    state.AutoBuffMode = M{['description'] = 'Buff Self and Party', 'Off', 'Auto'}
    state.AutoBuffMode:set_description('Off', "Do not buff self and party members.")
    state.AutoBuffMode:set_description('Auto', "Automatically buff self and party members.")

    state.AutoEnmityReductionMode = M{['description'] = 'Auto Enmity Reduction Mode', 'Off', 'Auto'}
    state.AutoEnmityReductionMode:set_description('Off', "Do not attempt to reduce enmity.")
    state.AutoEnmityReductionMode:set_description('Auto', "Automatically use abilities to reduce enmity.")
    
    state.AutoRestoreManaMode = M{['description'] = 'Auto Restore Mana Mode', 'Auto', 'Off'}
    state.AutoRestoreManaMode:set_description('Auto', "Use weapon skills to recover MP when low.")

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




