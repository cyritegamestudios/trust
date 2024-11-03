-- Settings file for SAM
return {
    Version = 2,
    Default = {
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new("Hasso", L{CombatSkillsCondition.new(L{'Great Sword','Great Axe','Scythe','Polearm','Great Katana','Staff'})}, L{}),
            JobAbility.new("Sekkanoki", L{ MinTacticalPointsCondition.new(1500), InBattleCondition.new() })
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
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MaxTacticalPointsCondition.new(1000), NotCondition.new(L{ModeCondition.new("AutoBuffMode", "Off")})}, JobAbility.new("Meditate", L{}, L{}), "Self")
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("SAM")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            },
        }
    }
}