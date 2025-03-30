---------------------------
-- Job file for Summoner.
-- @class module
-- @name Summoner

local Job = require('cylibs/entity/jobs/job')
local Summoner = setmetatable({}, {__index = Job })
Summoner.__index = Summoner

local avatar_to_blood_pacts = T{
    Carbuncle = L{ 'Shining Ruby' },
    ["Cait Sith"] = L{ 'Reraise II' },
    Ifrit = L{ 'Crimson Howl', 'Inferno Howl' },
    Shiva = L{ 'Frost Armor', 'Crystal Blessing' },
    Garuda = L{ 'Hastega', 'Hastega II', 'Aerial Armor', 'Fleet Wind' },
    Titan = L{ 'Earthen Ward', 'Earthen Armor' },
    Ramuh = L{ 'Rolling Thunder', 'Lightning Armor' },
    Leviathan = L{ 'Soothing Current' },
    Fenrir = L{ 'Ecliptic Growl', 'Ecliptic Howl', 'Heavenward Howl' },
    Diabolos = L{ 'Noctoshield', 'Dream Shroud' },
    Siren = L { 'Katabatic Blades', 'Chinook', "Wind's Blessing" },
    Atomos = L{},
    Alexander = L{},
    Odin = L{},
}

-------
-- Default initializer for a new Summoner.
-- @treturn SMN A Summoner
function Summoner.new()
    local self = setmetatable(Job.new('SMN', L{ 'Dispelga', 'Impact' }), Summoner)
    return self
end

-------
-- Destroy function for a Summoner.
function Summoner:destroy()
    Job.destroy(self)
end

-------
-- Returns a list of known job abilities.
-- @tparam function filter Optional filter function
-- @treturn list List of known job ability ids
function Summoner:get_job_abilities(filter)
    filter = filter or function(_) return true end
    local job_abilities = Job.get_job_abilities(self, filter)
    job_abilities = (job_abilities + self:get_blood_pact_wards():map(function(buff) return buff:get_ability_id() end):filter(filter)):unique(function(job_ability_id) return job_ability_id end)
    return job_abilities
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function Summoner:get_cure_spell(hp_missing)
    return nil
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Summoner:get_aoe_spells()
    return L{ 'Level ? Holy', 'Thunderspark' }
end

-------
-- Returns the name of the spirit pact that aligns with the current day.
-- @treturn string Localized name of the spirit pact (e.g. Earth Spirit)
function Summoner:get_spirit_for_current_day()
    local day_to_spirit = T{
        Firesday = 'Fire Spirit',
        Earthsday = 'Earth Spirit',
        Watersday = 'Water Spirit',
        Windsday = 'Air Spirit',
        Iceday = 'Ice Spirit',
        Lightningday = 'Thunder Spirit',
        Lightsday = 'Light Spirit',
        Darksday = 'Dark Spirit'
    }
    local spirit_name = day_to_spirit[res.days[windower.ffxi.get_info().day].en]
    if spell_util.knows_spell(res.spells:with('en', spirit_name).id) then
        return spirit_name
    end
    return 'Earth Spirit'
end

-------
-- Returns all Blood Pact: Ward matching the given filter.
-- @tparam function filter Filter function for blood pacts (optional)
-- @treturn list List of JobAbility
function Summoner:get_blood_pact_wards(filter)
    if filter == nil then
        filter = function(_) return true  end
    end
    local all_blood_pacts = L(res.job_abilities:with_all('type', 'BloodPactWard')):filter(filter):compact_map():map(function(blood_pact) return JobAbility.new(blood_pact.en)  end)
    return all_blood_pacts
end

-------
-- Returns the named of the Avatar required to use the given blood pact.
-- @tparam string blood_pact_name Name of the blood pact (see res/job_abilities.lua)
-- @treturn string Name of the Avatar
function Summoner:get_avatar_name(blood_pact_name)
    for avatar_name, blood_pact_names in pairs(avatar_to_blood_pacts) do
        if blood_pact_names:contains(blood_pact_name) then
            return avatar_name
        end
    end
    return nil
end

-------
-- Returns a list of conditions for an ability.
-- @tparam Spell|JobAbility ability The ability
-- @treturn list List of conditions
function Summoner:get_conditions_for_ability(ability)
    local conditions = Job.get_conditions_for_ability(self, ability)
    if res.spells[ability:get_ability_id()] and res.spells[ability:get_ability_id()].type == 'SummonerPact'
            or res.job_abilities[ability:get_ability_id()] and res.job_abilities[ability:get_ability_id()].type == 'BloodPactWard' then
        conditions:append(NotCondition.new(L{InTownCondition.new()}))
    end
    return conditions
end

return Summoner