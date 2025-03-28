-- Settings file for DRG
return {
    Version = 1,
    Default = {
        DebuffSettings = {
            Gambits = L{
            }
        },
        BuffSettings = {
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
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Spirit Surge")}), NotCondition.new(L{HasPetCondition.new()}), ModeCondition.new('AutoPetMode', 'Auto')}, JobAbility.new("Call Wyvern", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{HasPetCondition.new(L{}), PetHitPointsPercentCondition.new(25, "<=")}, JobAbility.new("Spirit Link", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasPetCondition.new(L{}), PetTacticalPointsCondition.new(3000, "=="), MaxTacticalPointsCondition.new(500)}, JobAbility.new("Spirit Link", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{HasPetCondition.new(L{}), InBattleCondition.new()}, JobAbility.new("Spirit Bond", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasPetCondition.new(L{})}, JobAbility.new("Steady Wing", L{}, L{}), "Self"),
            },
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(ItemCountCondition.new("Angon", 1, ">="), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MinHitPointsPercentCondition.new(80), "Enemy")}, JobAbility.new("Angon", L{}, L{}), "Enemy", L{}),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000), InBattleCondition.new(), MaxDistanceCondition.new(9)}, JobAbility.new("Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000), InBattleCondition.new(), MaxDistanceCondition.new(9)}, JobAbility.new("High Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000), InBattleCondition.new(), MaxDistanceCondition.new(9)}, JobAbility.new("Soul Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{MaxTacticalPointsCondition.new(1000), InBattleCondition.new(), MaxDistanceCondition.new(9)}, JobAbility.new("Spirit Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{MaxHitPointsPercentCondition.new(10)}, JobAbility.new("Super Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("DRG")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"Food"})
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
