-- Settings file for MNK
return {
    Version = 1,
    Default = {
        SelfBuffs = L{
            JobAbility.new('Impetus', L{InBattleCondition.new()}),
            JobAbility.new('Footwork', L{InBattleCondition.new()}),
            JobAbility.new('Mantra', L{InBattleCondition.new()}),
        },
        PartyBuffs = L{

        },
        PullSettings = {
            Abilities = L{
                JobAbility.new("Chi Blast", L{}, L{}),
                RangedAttack.new(),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MeleeAccuracyCondition.new(75, "<=")}, JobAbility.new('Focus', L{}), "Self"),
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(25)}, JobAbility.new("Chakra", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("MNK")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}