---------------------------
-- Wrapper around elemental magic used with Immanence.
-- @class module
-- @name ElementalMagic

local res = require('resources')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local ElementalMagic = setmetatable({}, {__index = SkillchainAbility })
ElementalMagic.__index = ElementalMagic
ElementalMagic.__type = "ElementalMagic"
ElementalMagic.__class = "ElementalMagic"

-------
-- Default initializer for a new elemental magic.
-- @tparam string spell_name Localized name of the spell (see res/spells.lua)
-- @tparam list conditions (optional) List of conditions that must be met to use this ability
-- @treturn ElementalMagic An elemental magic spell
function ElementalMagic.new(spell_name, conditions)
    conditions = conditions or L{}
    local spell = res.spells:with('en', spell_name)
    if spell == nil then
        return nil
    end
    local immanence_ready = JobAbilityRecastReadyCondition.new('Immanence')
    if not conditions:contains(immanence_ready) then
        conditions:append(immanence_ready)
    end
    local self = setmetatable(SkillchainAbility.new('spells', spell.id, conditions), ElementalMagic)
    return self
end

function ElementalMagic:serialize()
    return "ElementalMagic.new(" .. serializer_util.serialize_args(self:get_name()) .. ")"
end

function ElementalMagic:__eq(otherItem)
    if not L{ SkillchainAbility.__class, ElementalMagic.__class }:contains(otherItem.__class) then
        return false
    end
    return otherItem:get_name() == self:get_name()
end

return ElementalMagic