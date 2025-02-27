local ClaimedCondition = require('cylibs/conditions/claimed')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Tank = setmetatable({}, {__index = Gambiter })
Tank.__index = Tank

state.AutoTankMode = M{['description'] = 'Auto Tank Mode', 'Off', 'Auto'}
state.AutoTankMode:set_description('Auto', "Okay, I'll tank for the party.")

function Tank.new(action_queue, job_abilities, spells)
    local self = setmetatable(Gambiter.new(action_queue, {}, state.AutoTankMode), Tank)

    local gambit_settings = {
        Gambits = (spells + job_abilities):map(function(ability)
            return Gambit.new(GambitTarget.TargetType.Enemy, L{
                ClaimedCondition.new()
            }, ability, Condition.TargetType.Enemy)
        end)
    }
    self:set_gambit_settings(gambit_settings)

    return self
end

function Tank:get_cooldown()
    return 9
end

function Tank:allows_multiple_actions()
    return true
end

function Tank:get_type()
    return "tank"
end

function Tank:allows_duplicates()
    return true
end

return Tank