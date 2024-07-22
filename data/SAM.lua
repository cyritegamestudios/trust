-- Settings file for SAM
return {
    Version = 2,
    Default = {
        AutoFood = "Grape Daifuku",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Hasso', L{}, L{}, nil),
            JobAbility.new('SpSekkanoki', L{ MinTacticalPointsCondition.new(1500), InBattleCondition.new() })
        },
        PullSettings = {
            Abilities = L{
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MaxTacticalPointsCondition.new(1000), NotCondition.new(L{ModeCondition.new("AutoBuffMode", "Off")})}, JobAbility.new("Meditate", L{}, L{}), "Self")
            },
            Gambits = L{

            },
        }
    }
}