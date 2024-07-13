---------------------------
-- Disengages from the current target.
-- @class module
-- @name DisengageAction


local packets = require('packets')

local Action = require('cylibs/actions/action')
local DisengageAction = setmetatable({}, {__index = Action })
DisengageAction.__index = DisengageAction

function DisengageAction.new()
    local conditions = L{
        InBattleCondition.new(),
    }
    local self = setmetatable(Action.new(0, 0, 0, nil, conditions), DisengageAction)

    self:debug_log_create(self:gettype())

    return self
end

function DisengageAction:destroy()
    self:debug_log_destroy(self:gettype())

    Action.destroy(self)
end

function DisengageAction:perform()
    local p = packets.new('outgoing', 0x01A)

    p['Target'] = windower.ffxi.get_player().id
    p['Target Index'] = windower.ffxi.get_player().index
    p['Category'] = 0x04 -- Disengage
    p['Param'] = 0
    p['X Offset'] = 0
    p['Z Offset'] = 0
    p['Y Offset'] = 0

    packets.inject(p)
end

function DisengageAction:gettype()
    return "disengageaction"
end

function DisengageAction:getrawdata()
    local res = {}
    return res
end

function DisengageAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Disengaging'
end

function DisengageAction:debug_string()
    return "DisengageAction"
end

return DisengageAction



