local serializer_util = require('cylibs/util/serializer_util')

local GambitTarget = {}
GambitTarget.__index = GambitTarget
GambitTarget.__class = "GambitTarget"

GambitTarget.TargetType = T{}
GambitTarget.TargetType.Self = "Self"
GambitTarget.TargetType.Ally = "Ally"
GambitTarget.TargetType.Enemy = "Enemy"
--GambitTarget.TargetType.AllTargets = S{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally, GambitTarget.TargetType.Enemy }

function GambitTarget.new(targetType)
    local self = setmetatable({}, GambitTarget)

    self.targetType = targetType

    return self
end

function GambitTarget:getTargetType()
    return self.targetType
end

function GambitTarget:serialize()
    return "GambitTarget.new(" .. serializer_util.serialize_args(self.targetType) .. ")"
end

return GambitTarget