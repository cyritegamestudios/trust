---------------------------
-- Action to turn away from or turn to face a target.
-- @class module
-- @name TurnAction

local Action = require('cylibs/actions/action')
local TurnAction = setmetatable({}, {__index = Action })
TurnAction.__index = TurnAction

function TurnAction.new(target_index, turn_away)
    local self = setmetatable(Action.new(0, 0, 0, target_index), TurnAction)
    self.identifier = 'turn_'..tostring(turn_away)
    self.turn_away = turn_away
    return self
end

function TurnAction:perform()
    local target = windower.ffxi.get_mob_by_index(self.target_index)

    if self.turn_away then
        state.AutoFaceMobMode:set('Away')
        player_util.face_away(target)
    else
        state.AutoFaceMobMode:set('Auto')
        player_util.face(target)
    end

    coroutine.sleep(2)

    self:complete(true)
end

function TurnAction:gettype()
    return "turnaction"
end

function TurnAction:tostring()
    if self.turn_away then
        return "Turn Around"
    else
        return "Turn to Face"
    end
end

function TurnAction:debugstring()
    return "TurnAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return TurnAction



