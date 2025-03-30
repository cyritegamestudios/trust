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
            Gambits = L{
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
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Counter Boost", "Magic Def. Boost"}, 1)}), "Self"), GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(HasPetCondition.new(L{"VivaciousVickie"}), "Self"), GambitCondition.new(ModeCondition.new("AutoBuffMode", "Auto"), "Self")}, JobAbility.new("Zealous Snort", L{}, L{}), "Self", L{"JugPet"}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("BST"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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