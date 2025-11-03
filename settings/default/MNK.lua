-- Settings file for MNK
return {
    Version = 1,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 0.5,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self")}, JobAbility.new("Impetus", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self")}, JobAbility.new("Footwork", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self")}, JobAbility.new("Mantra", L{}), "Self", L{"Buffs"})
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
            Gambits = L{
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, JobAbility.new("Chi Blast", L{}, L{}), "Enemy", L{"Pulling"}),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20,
            MaxNumTargets = 1,
        },
        TargetSettings = {
            Retry = false
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{GambitCondition.new(MeleeAccuracyCondition.new(75, "<="), "Self")}, JobAbility.new('Focus', L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(MaxHitPointsPercentCondition.new(25), "Self")}, JobAbility.new("Chakra", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("MNK"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        ReactionSettings = {
            Gambits = L{
            }
        },
        GearSwapSettings = {
            Enabled = true,
            Language = "en"
        },
    }
}