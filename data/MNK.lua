-- Settings file for MNK
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Impetus', L{InBattleCondition.new()}),
            JobAbility.new('Footwork', L{InBattleCondition.new()}),
            JobAbility.new('Mantra', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                JobAbility.new("Chi Blast", L{}, L{})
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MeleeAccuracyCondition.new(75, "<=")}, JobAbility.new('Focus', L{}), "Self"),
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(25)}, JobAbility.new("Chakra", L{}, L{}), "Self")
            },
            Gambits = L{

            }
        },
    }
}