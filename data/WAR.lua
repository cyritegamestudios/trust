-- Settings file for WAR
return {
    Version = 1,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Berserk", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Aggressor", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Warcry", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Restraint", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Blood Rage", L{}, L{}), "Self", L{"Buffs"}),
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
            Retry = true
        },
        GambitSettings = {
            Default = L{

            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("WAR")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}