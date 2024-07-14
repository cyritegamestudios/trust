local serializer_util = require('cylibs/util/serializer_util')
local Spell = require('cylibs/battle/spell')

local SpellGambitReaction = {}
SpellGambitReaction.__index = SpellGambitReaction
SpellGambitReaction.__class = "SpellGambitReaction"

function SpellGambitReaction.new(spell)
    local self = setmetatable({}, SpellGambitReaction)

    self.spell = spell

    return self
end

function SpellGambitReaction:getAction(target, dependency_container)
    local action = self.spell:to_action(target:get_mob().index, dependency_container:resolve(Player.__class))
    return action
end

function SpellGambitReaction:serialize()
    return "SpellGambitReaction.new(" .. serializer_util.serialize_args(self.spell_name) .. ")"
end

return SpellGambitReaction