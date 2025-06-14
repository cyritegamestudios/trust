-- Settings file for COR
return {
    Version = 2,
    Default = {
        Shooter = {
            Delay = 1.5,
            MaxTP = 1000,
        },
        RollSettings = {
            Gambits = L{

            },
            Roll1 = Roll.new("Chaos Roll", true),
            Roll2 = Roll.new("Samurai Roll", false),
            DoubleUpThreshold = 7,
            NumRequiredPartyMembers = 1,
            PrioritizeElevens = false,
        },
        Roll1 = Roll.new("Chaos Roll", true),
        Roll2 = Roll.new("Samurai Roll", false),
        DebuffSettings = {
            Gambits = L{
            }
        },
        BuffSettings = {
            Gambits = L{

            }
        },
        PullSettings = {
            Gambits = L{
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
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoShootMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new("Triple Shot") }), "Self")}, JobAbility.new("Triple Shot", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("COR"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        ReactionSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(GainDebuffCondition.new("Dia"), "Enemy")}, JobAbility.new("Light Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GambitCondition.new(GainDebuffCondition.new("silence"), "Enemy")}, JobAbility.new("Wind Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GambitCondition.new(GainDebuffCondition.new("slow"), "Enemy")}, JobAbility.new("Earth Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GambitCondition.new(GainDebuffCondition.new("paralysis"), "Enemy")}, JobAbility.new("Ice Shot", L{}, L{}), "Enemy"),
            }
        },
        GearSwapSettings = {
            Enabled = true,
            Language = "en"
        },
    }
}