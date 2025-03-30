-- Settings file for SAM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(CombatSkillsCondition.new(L{'Great Sword','Great Axe','Scythe','Polearm','Great Katana','Staff'}), "Self")}, JobAbility.new("Hasso", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(MinTacticalPointsCondition.new(1500), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Sekkanoki", L{}), "Self", L{"Buffs"}),
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
            Retry = false,
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{GambitCondition.new(MaxTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(ModeCondition.new("AutoBuffMode", "Auto"), "Self")}, JobAbility.new("Meditate", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("SAM"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            },
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