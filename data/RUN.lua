-- Settings file for RUN
return {
    Version = 1,
    Default = {
        PartyBuffs = L{

        },
        SelfBuffs = L{
            Spell.new("Temper", L{}, nil, nil, L{}),
            Spell.new("Crusade", L{}, nil, nil, L{}),
            Spell.new("Refresh", L{}, nil, nil, L{}),
            Spell.new("Regen IV", L{}, nil, nil, L{}),
            Spell.new("Shell V", L{}, nil, nil, L{}),
            Spell.new("Phalanx", L{}, nil, nil, L{}),
            JobAbility.new('Swordplay', L{InBattleCondition.new()}),
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Flash', L{}, L{})
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
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(30), HasRunesCondition.new(3)}, JobAbility.new("Vivacious Pulse", L{}, L{}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3)}, JobAbility.new("Valiance", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3)}, JobAbility.new("Vallation", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("RUN")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}