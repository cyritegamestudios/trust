-- Settings file for DNC
return {
    Version = 1,
    Default = {
        CureSettings = {
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
                Gambit.new("Self", L{InBattleCondition.new()}, JobAbility.new("Haste Samba", L{}, L{}), "Self", L{"Buffs"})
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
            Retry = true
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Enemy", L{HasBuffCondition.new("Presto"), InBattleCondition.new()}, JobAbility.new("Box Step", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{HasDazeCondition.new("Sluggish Daze", 5, "<"), InBattleCondition.new()}, JobAbility.new("Presto", L{}, L{}), "Enemy", L{}),
                Gambit.new("Self", L{MaxTacticalPointsCondition.new(900), HasBuffsCondition.new(L{"Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1)}, JobAbility.new("Reverse Flourish", L{}, L{}), "Self", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("DNC")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}