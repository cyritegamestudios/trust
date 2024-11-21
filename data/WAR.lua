-- Settings file for WAR
return {
    Version = 1,
    Default = {
        SelfBuffs = L{
            JobAbility.new('Berserk', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Aggressor', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Warcry', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Restraint', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Blood Rage', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Retaliation', L{}, L{}, nil),
        },
        PartyBuffs = L{

        },
        PullSettings = {
            Abilities = L{
                JobAbility.new('Provoke', L{}, L{})
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

            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("WAR")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}