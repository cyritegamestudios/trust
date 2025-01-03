-- Settings file for RNG
return {
    Version = 2,
    Default = {
        Shooter = {
            Delay = 1.5
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto"), StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Velocity Shot", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto"), StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Double Shot", L{}, L{}), "Self", L{"Buffs"})
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Abilities = L{
                RangedAttack.new()
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
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("RNG")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}