local ElementalMagic = require('cylibs/battle/abilities/elemental_magic')
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
function ElementalMagicSkillSettings.new(blacklist, defaultSpellName)
    local self = setmetatable({}, ElementalMagicSkillSettings)
    self.blacklist = blacklist
    self.known_spells = spell_util.get_spells(function(spell)
        return skills.spells[spell.id] ~= nil and spell.type == 'BlackMagic'
    end):map(function(spell)
        return Spell.new(spell.en)
    end)
    self.defaultSpellName = defaultSpellName
    self.defaultSpellId = defaultSpellName and spell_util.spell_id(defaultSpellName)
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
    if self.defaultSpellId then
        local ability = SkillchainAbility.new('spells', self.defaultSpellId, L{ JobAbilityRecastReadyCondition.new('Immanence') })
        if ability then
            return ability
        end
    end
    return nil
end

function ElementalMagicSkillSettings:set_default_ability(ability_name)
    local ability = self:get_ability(ability_name)
    if ability then
        self.defaultSpellId = ability:get_ability_id()
        self.defaultSpellName = ability:get_name()
    else
        self.defaultSpellId = nil
        self.defaultSpellName = nil
    end
end

function ElementalMagicSkillSettings:get_id()
    return nil
end

function ElementalMagicSkillSettings:get_name()
    return 'Immanence'
end

function ElementalMagicSkillSettings:get_ability(ability_name)
    return ElementalMagic.new(ability_name)
end

function ElementalMagicSkillSettings:serialize()
    self.blacklist = L(S(self.blacklist:extend(L{
        'Fire II', 'Fire III', 'Fire IV', 'Fire V',
        'Blizzard II', 'Blizzard III', 'Blizzard IV', 'Blizzard V',
        'Aero II', 'Aero III', 'Aero IV', 'Aero V',
        'Stone II', 'Stone III', 'Stone IV', 'Stone V',
        'Thunder II', 'Thunder III', 'Thunder IV', 'Thunder V',
        'Water II', 'Water III', 'Water IV', 'Water V'
    })))

    return "ElementalMagicSkillSettings.new(" .. serializer_util.serialize_args(self.blacklist, self.defaultSpellName or '') .. ")"
end

return ElementalMagicSkillSettings