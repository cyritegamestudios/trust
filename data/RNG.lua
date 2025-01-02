-- Settings file for RNG
return {
    Version = 2,
    Default = {
        Shooter = {
            Delay = 1.5
        },
        SelfBuffs = L{
            JobAbility.new('Velocity Shot', L{InBattleCondition.new()}),
        },
        PartyBuffs = L{

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
                Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto")}, JobAbility.new("Double Shot", L{}, L{}), "Self", L{"Abilities"}),
                Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto")}, JobAbility.new("Velocity Shot", L{}, L{}), "Self", L{"Abilities"}),
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}