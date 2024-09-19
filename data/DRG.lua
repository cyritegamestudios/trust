-- Settings file for DRG
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{

        },
        PullSettings = {
            Abilities = L{
                RangedAttack.new(),
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Spirit Surge")}), NotCondition.new(L{HasPetCondition.new()})}, JobAbility.new("Call Wyvern", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{HasPetCondition.new(L{}), PetHitPointsPercentCondition.new(25, "<=")}, JobAbility.new("Spirit Link", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasPetCondition.new(L{}), PetTacticalPointsCondition.new(3000, "=="), MaxTacticalPointsCondition.new(500)}, JobAbility.new("Spirit Link", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{HasPetCondition.new(L{}), InBattleCondition.new()}, JobAbility.new("Spirit Bond", L{}, L{}), "Self"),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000)}, JobAbility.new("Jump", L{}, L{}), "Self"),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000)}, JobAbility.new("High Jump", L{}, L{}), "Self"),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000)}, JobAbility.new("Soul Jump", L{}, L{}), "Self"),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000)}, JobAbility.new("Spirit Jump", L{}, L{}), "Self"),
                Gambit.new("Enemy", L{MaxHitPointsPercentCondition.new(10)}, JobAbility.new("Super Jump", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasPetCondition.new(L{})}, JobAbility.new("Steady Wing", L{}, L{}), "Self"),
            },
            Gambits = L{
                Gambit.new("Enemy", L{MinHitPointsPercentCondition.new(80)}, JobAbility.new("Angon", L{}, L{}), "Enemy"),
            }
        },
    }
}
