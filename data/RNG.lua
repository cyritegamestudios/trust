-- Settings file for RNG
return {
    Version = 2,
    Default = {
        Shooter = {
            Delay = 0,
            MaxTP = 1000,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoShootMode", "Auto"), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Velocity Shot", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoShootMode", "Auto"), "Self"), GambitConditionn.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Double Shot", L{}, L{}), "Self", L{"Buffs"})
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
                Gambit.new("Enemy", L{}, RangedAttack.new(), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
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
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("RNG"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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