-- Settings file for BST
return {
    Version = 1,
    Default = {
        SelfBuffs = L{
            {
                Familiar = "VivaciousVickie",
                ReadyMove = "Zealous Snort",
                Buff = "Counter Boost"
            }
        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Killer Instinct', L{InBattleCondition.new()}),
            JobAbility.new('Spur', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                Approach.new()
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BST")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}