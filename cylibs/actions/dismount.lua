---------------------------
-- Action representing a dismount
-- @class module
-- @name Dismount

local packets = require('packets')

local Action = require('cylibs/actions/action')
local DismountAction = setmetatable({}, {__index = Action })
DismountAction.__index = DismountAction
DismountAction.__eq = DismountAction.is_equal
DismountAction.__class = "DismountAction"

function DismountAction.new()
    local conditions = L{}

    local self = setmetatable(Action.new(0, 0, 0, nil, conditions), DismountAction)
    return self
end

function DismountAction:perform()
    logger.notice(self.__class, 'perform')

    local p = packets.new('outgoing', 0x01A)

    p['Target'] = windower.ffxi.get_player().id
    p['Target Index'] = windower.ffxi.get_player().index
    p['Category'] = 0x12 -- Dismount
    p['Param'] = 0
    p['X Offset'] = 0
    p['Z Offset'] = 0
    p['Y Offset'] = 0

    packets.inject(p)

    self:complete(true)
end

function DismountAction:gettype()
    return "dismountaction"
end

function DismountAction:getidentifier()
    return self:gettype()
end

function DismountAction:getrawdata()
    local res = {}
    res.dismountaction = {}
    return res
end

function DismountAction:copy()
    return DismountAction.new()
end

function DismountAction:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype()
end

function DismountAction:tostring()
    return "Dismount"
end

function DismountAction:debug_string()
    return "DismountAction: %s":format("Dismount")
end

return DismountAction