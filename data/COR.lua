-- Settings file for COR
return {
    Version = 2,
    Default = {
        Shooter = {
            Delay = 1.5
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
                Gambit.new("Enemy", L{GainDebuffCondition.new("Dia")}, JobAbility.new("Light Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GainDebuffCondition.new("silence")}, JobAbility.new("Wind Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GainDebuffCondition.new("slow")}, JobAbility.new("Earth Shot", L{}, L{}), "Enemy"),
                Gambit.new("Enemy", L{GainDebuffCondition.new("paralysis")}, JobAbility.new("Ice Shot", L{}, L{}), "Enemy"),
                Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto")}, JobAbility.new("Triple Shot", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("COR")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}