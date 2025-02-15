-- Settings file for SAM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{CombatSkillsCondition.new(L{'Great Sword','Great Axe','Scythe','Polearm','Great Katana','Staff'})}, JobAbility.new("Hasso", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{MinTacticalPointsCondition.new(1500), InBattleCondition.new()}, JobAbility.new("Sekkanoki", L{}), "Self", L{"Buffs"}),
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
                Gambit.new("Self", L{MaxTacticalPointsCondition.new(1000), NotCondition.new(L{ModeCondition.new("AutoBuffMode", "Off")})}, JobAbility.new("Meditate", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("SAM")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"Food"})
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