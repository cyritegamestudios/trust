local serializer_util = require('cylibs/util/serializer_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local skills = require('cylibs/res/skills')
local spell_util = require('cylibs/util/spell_util')

local ElementalMagicSkillSettings = {}
ElementalMagicSkillSettings.__index = ElementalMagicSkillSettings
ElementalMagicSkillSettings.__type = "ElementalMagicSkillSettings"

-------
-- Default initializer for a new skillchain settings representing elemental magic used with Immanence.
-- @tparam list blacklist Blacklist of spell names
-- @treturn ElementalMagicSkillSettings An elemental magic settings
function ElementalMagicSkillSettings.new(blacklist)
    local self = setmetatable({}, ElementalMagicSkillSettings)
    self.blacklist = blacklist
    self.known_spells = spell_util.get_spells(function(spell)
        return skills.spells[spell.id] ~= nil and spell.type == 'BlackMagic'
    end):map(function(spell)
        return Spell.new(spell.en)
    end)
    return self
end

-------
-- Returns whether this settings applies to the given player.
-- @tparam Player player The Player
-- @treturn boolean True if the settings is applicable to the player, false otherwise
function ElementalMagicSkillSettings:is_valid(player)
    return true
end

-------
-- Returns the list of skillchain abilities included in this settings. Omits abilities on the blacklist but does
-- not check conditions for whether an ability can be performed.
-- @treturn list A list of SkillchainAbility
function ElementalMagicSkillSettings:get_abilities()
    local spells = self.known_spells:filter(
            function(spell)
                return not self.blacklist:contains(spell:get_name())
            end):map(
            function(spell)
                return SkillchainAbility.new('spells', spell:get_spell().id, L{ JobAbilityRecastReadyCondition.new('Immanence') })
            end)
    return spells
end

function ElementalMagicSkillSettings:get_default_ability()
    return nil
end

function ElementalMagicSkillSettings:get_name()
    return 'Immanence'
end

function ElementalMagicSkillSettings:get_ability(ability_name)
    return SkillchainAbility.new('spells', res.spells:with('en', ability_name).id)
end

function ElementalMagicSkillSettings:serialize()
    return "ElementalMagicSkillSettings.new(" .. serializer_util.serialize_args(self.blacklist) .. ")"
end

return ElementalMagicSkillSettings