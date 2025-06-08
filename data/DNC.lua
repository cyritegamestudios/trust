-- Settings file for DNC
return {
    Version = 1,
    Default = {
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 2), "Self")}, JobAbility.new("Divine Waltz II"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 72, 2), "Self")}, JobAbility.new("Divine Waltz"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Self")}, JobAbility.new("Curing Waltz V"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, JobAbility.new("Curing Waltz IV"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Self")}, JobAbility.new("Curing Waltz III"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Ally")}, JobAbility.new("Curing Waltz V"), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, JobAbility.new("Curing Waltz IV"), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Ally")}, JobAbility.new("Curing Waltz III"), "Ally", L{}, true)
            },
            Thresholds = {
                Emergency = 40,
                Default = 78,
                ["Curing Waltz II"] = 0,
                ["Curing Waltz III"] = 600,
                ["Curing Waltz IV"] = 1500,
                ["Divine Waltz"] = 0,
                ["Divine Waltz II"] = 600,
            },
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Haste Samba", L{}, L{}), "Self", L{"Buffs"})
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
                Gambit.new("Enemy", L{}, JobAbility.new("Animated Flourish", L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, RangedAttack.new(), "Enemy", L{"Pulling"}),
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
                Gambit.new("Enemy", L{GambitCondition.new(HasBuffCondition.new("Presto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Box Step", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(HasDazeCondition.new("Sluggish Daze", 5, "<"), "Enemy"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Presto", L{}, L{}), "Enemy", L{}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Finishing Move (6+)")}), "Self")}, JobAbility.new("No Foot Rise", L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(MaxTacticalPointsCondition.new(900), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1), "Self")}, JobAbility.new("Reverse Flourish", L{}, L{}), "Self", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("DNC"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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