local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Bubbler = setmetatable({}, {__index = Gambiter })
Bubbler.__index = Bubbler
Bubbler.__class = Bubbler

state.AutoGeoMode = M{['description'] = 'Use geocolures', 'Off', 'Auto'}
state.AutoGeoMode:set_description('Auto', "Use Geocolure spells.")

-------
-- Default initializer for a bubbler role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T geomancy_settings Geomancy settings
-- @treturn Healer A healer role
function Bubbler.new(action_queue, geomancy_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoGeoMode }), Bubbler)

    self.job = job
    self.dispose_bag = DisposeBag.new()

    self:set_geomancy_settings(geomancy_settings)

    return self
end

function Bubbler:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Bubbler:on_add()
    Gambiter.on_add(self)
end

function Bubbler:get_cooldown()
    return 4
end

function Bubbler:allows_duplicates()
    return false
end

function Bubbler:get_type()
    return "bubbler"
end

function Bubbler:allows_multiple_actions()
    return false
end

-------
-- Sets the nuke settings.
-- @tparam T geomancy_settings Geomancy settings
function Bubbler:set_geomancy_settings(geomancy_settings)
    self.geocolure = geomancy_settings.Geo

    local gambit_settings = {
        Gambits = L{},
    }

    gambit_settings.Gambits = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(HasPetCondition.new(), GambitTarget.TargetType.Self),
            GambitCondition.new(PetHitPointsPercentCondition.new(25, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
        }, JobAbility.new('Life Cycle'), Condition.TargetType.Self),
        --[[Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(HasPetCondition.new(), GambitTarget.TargetType.Self),
            GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Bolster') }), GambitTarget.TargetType.Self),
        }, JobAbility.new('Ecliptic Attrition'), Condition.TargetType.Self),
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(HasPetCondition.new(), GambitTarget.TargetType.Self),
            GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Bolster') }), GambitTarget.TargetType.Self),
        }, JobAbility.new('Lasting Emanation'), Condition.TargetType.Self),]]
    }

    if L(geomancy_settings.Geo:get_spell().targets):contains("Enemy") then
        local geocolure = Spell.new(geomancy_settings.Geo:get_name(), L{ 'Blaze of Glory' })
        geocolure:set_requires_all_job_abilities(false)

        gambit_settings.Gambits = gambit_settings.Gambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasPetCondition.new(), GambitTarget.TargetType.Self),
                GambitCondition.new(PetDistanceCondition.new(6, Condition.Operator.GreaterThan), GambitTarget.TargetType.Enemy),
            }, JobAbility.new('Full Circle'), Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(NotCondition.new(L{ HasPetCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(PartyClaimedCondition.new(true), GambitTarget.TargetType.Enemy),
                GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Bolster') }), GambitTarget.TargetType.Self),
            }, geocolure, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(NotCondition.new(L{ HasPetCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(PartyClaimedCondition.new(true), GambitTarget.TargetType.Enemy),
                GambitCondition.new(HasBuffCondition.new('Bolster'), GambitTarget.TargetType.Self),
            }, Spell.new(geomancy_settings.Geo:get_name()), Condition.TargetType.Self),
        }
    else
        local geocolure = Spell.new(geomancy_settings.Geo:get_name(), L{ 'Blaze of Glory' }, L{}, geomancy_settings.Geo:get_target())
        geocolure:set_requires_all_job_abilities(false)

        local target_type
        if geomancy_settings.Geo:get_target() == 'me' then
            target_type = GambitTarget.TargetType.Self
        else
            target_type = GambitTarget.TargetType.Ally
        end

        gambit_settings.Gambits = gambit_settings.Gambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasPetCondition.new(), GambitTarget.TargetType.Self),
                GambitCondition.new(PetDistanceCondition.new(6, Condition.Operator.GreaterThan), target_type),
            }, JobAbility.new('Full Circle'), Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasPetCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Bolster') }), GambitTarget.TargetType.Self),
            }, geocolure, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasPetCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(HasBuffCondition.new('Bolster'), GambitTarget.TargetType.Self),
            }, Spell.new(geomancy_settings.Geo:get_name(), L{}, L{}, geomancy_settings.Geo:get_target()), Condition.TargetType.Self),
        }
    end

    for gambit in gambit_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    self:set_gambit_settings(gambit_settings)
end

function Bubbler:get_default_conditions(gambit)
    local conditions = L{
        MaxDistanceCondition.new(20),
    }

    local ability_conditions = (L{} + self.job:get_conditions_for_ability(gambit:getAbility()))

    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Bubbler:get_gambit_targets(gambit_target_types)
    local targets_by_type = Gambiter.get_gambit_targets(self, gambit_target_types)

    if not L{ 'bt', 'me' }:contains(self.geocolure:get_target()) then
        local target = windower.ffxi.get_mob_by_target(self.geocolure:get_target())
        targets_by_type[GambitTarget.TargetType.Ally] = L{ self:get_party():get_party_member(target.id) }
    end
    return targets_by_type
end

return Bubbler