-- Settings file for MNK
return {
    Version = 1,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Impetus", L{}), "Self", L{}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Footwork", L{}), "Self", L{}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Mantra", L{}), "Self", L{})
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
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
        TargetSettings = {
            Retry = true
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
        GearSwapSettings = {
            Enabled = true
        },
    }
}