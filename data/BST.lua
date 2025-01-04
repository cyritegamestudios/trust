-- Settings file for BST
return {
    Version = 1,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{InBattleCondition.new(), HasPetCondition.new()}, JobAbility.new('Killer Instinct', L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{InBattleCondition.new(), HasPetCondition.new()}, JobAbility.new('Spur', L{}), "Self", L{"Buffs"}),
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
        TargetSettings = {
            Retry = true
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Counter Boost", "Magic Def. Boost"}, 1)}), InBattleCondition.new(), HasPetCondition.new(L{"VivaciousVickie"}), ModeCondition.new("AutoBuffMode", "Auto")}, JobAbility.new("Zealous Snort", L{}, L{}), "Self", L{"JugPet"}),
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BST")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}