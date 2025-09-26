-- Settings file for DRG
return {
    Version = 1,
    Default = {
        CombatSettings = {
            Distance = 2,
            MirrorDistance = 1.5,
        },
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
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Spirit Surge")}), "Self"), NotCondition.new(L{HasPetCondition.new()}), ModeCondition.new('AutoPetMode', 'Auto')}, JobAbility.new("Call Wyvern", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(HasPetCondition.new(L{}), "Self"), GambitCondition.new(PetHitPointsPercentCondition.new(25, "<="), "Self")}, JobAbility.new("Spirit Link", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasPetCondition.new(L{}), "Self"), GambitCondition.new(PetTacticalPointsCondition.new(3000, "=="), "Self"), GambitCondition.new(MaxTacticalPointsCondition.new(500), "Self")}, JobAbility.new("Spirit Link", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(HasPetCondition.new(L{}), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Spirit Bond", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasPetCondition.new(L{}), "Self")}, JobAbility.new("Steady Wing", L{}, L{}), "Self"),
            },
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(ItemCountCondition.new("Angon", 1, ">="), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MinHitPointsPercentCondition.new(80), "Enemy")}, JobAbility.new("Angon", L{}, L{}), "Enemy", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(MaxTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MaxDistanceCondition.new(9), "Self")}, JobAbility.new("Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(MaxTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MaxDistanceCondition.new(9), "Self")}, JobAbility.new("High Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(MaxTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MaxDistanceCondition.new(9), "Self")}, JobAbility.new("Soul Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(MaxTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MaxDistanceCondition.new(9), "Self")}, JobAbility.new("Spirit Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(MaxHitPointsPercentCondition.new(10), "Self")}, JobAbility.new("Super Jump", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("DRG"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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
