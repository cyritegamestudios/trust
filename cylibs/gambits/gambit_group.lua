local GambitTarget = require('cylibs/gambits/gambit_target')
local serializer_util = require('cylibs/util/serializer_util')

local GambitGroup = {}
GambitGroup.__index = GambitGroup
GambitGroup.__class = "GambitGroup"

function GambitGroup.new(gambits, target)
    local self = setmetatable({}, GambitGroup)

    self.gambits = gambits
    self.target = target

    for gambit in gambits do
        gambit.target = GambitTarget.new(GambitTarget.TargetType.Inherited)
    end

    return self
end

function GambitGroup:serialize()
    return "GambitGroup.new(" .. serializer_util.serialize_args(self.gambits, self.target) .. ")"
end

return GambitGroup