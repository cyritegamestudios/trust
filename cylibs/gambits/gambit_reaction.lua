local serializer_util = require('cylibs/util/serializer_util')

local GambitReaction = {}
GambitReaction.__index = GambitReaction
GambitReaction.__class = "GambitReaction"

GambitTarget.ReactionType = {}
GambitTarget.ReactionType.Spell = "Spell"
GambitTarget.ReactionType.JobAbility = "JobAbility"

function GambitReaction.new(reactionType)
    local self = setmetatable({}, GambitReaction)

    self.reactionType = reactionType

    return self
end

function GambitReaction:getAction(target)
    return nil
end

function GambitReaction:getReactionType()
    return self.reactionType
end

function GambitReaction:serialize()
    return "GambitReaction.new(" .. serializer_util.serialize_args(self.reactionType) .. ")"
end

return GambitReaction