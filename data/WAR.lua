-- Settings file for WAR
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
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Berserk", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Aggressor", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Warcry", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Restraint", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Blood Rage", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, JobAbility.new("Retaliation", L{}, L{}), "Self", L{})
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
                Gambit.new("Enemy", L{}, JobAbility.new("Provoke", L{}, L{}), "Enemy", L{"Pulling"}),
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
            Default = L{
                Gambit.new("Enemy", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self")}, JobAbility.new("Provoke", L{}), "Enemy", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("WAR"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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