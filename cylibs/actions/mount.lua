---------------------------
-- Action representing a mount
-- @class module
-- @name Mount

local packets = require('packets')

local Action = require('cylibs/actions/action')
local MountAction = setmetatable({}, {__index = Action })
MountAction.__index = MountAction
MountAction.__eq = MountAction.is_equal
MountAction.__class = "MountAction"

function MountAction.new(mount_id)
    local conditions = L{
        NotCondition.new(L{InMogHouseCondition.new()}),
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror'}, 1)}, windower.ffxi.get_player().index),
    }

    local self = setmetatable(Action.new(0, 0, 0, nil, conditions), MountAction)
    self.mount_id = mount_id
    return self
end

function MountAction:perform()
    logger.notice(self.__class, 'perform', res.mounts[self.mount_id].en)

    local p = packets.new('outgoing', 0x01A)

    p['Target'] = windower.ffxi.get_player().id
    p['Target Index'] = windower.ffxi.get_player().index
    p['Category'] = 0x1A -- Mount
    p['Param'] = self.mount_id
    p['X Offset'] = 0
    p['Z Offset'] = 0
    p['Y Offset'] = 0

    packets.inject(p)

    self:complete(true)
end

function MountAction:get_mount_id()
    return self.mount_id
end

function MountAction:gettype()
    return "mountaction"
end

function MountAction:getidentifier()
    return self.mount_id
end

function MountAction:getrawdata()
    local res = {}

    res.mountaction = {}
    res.mountaction.mount_id = self:get_mount_id()

    return res
end

function MountAction:copy()
    return MountAction.new(self:get_mount_id())
end

function MountAction:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_mount_id() == action:get_mount_id()
end

function MountAction:tostring()
    return res.mounts[self:get_mount_id()].en
end

function MountAction:debug_string()
    return "MountAction: %s":format(res.mounts[self:get_mount_id()].en)
end

return MountAction