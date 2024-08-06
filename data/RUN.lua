-- Settings file for RUN
return {
    Version = 1,
    Default = {
        AutoFood = "Miso Ramen",
        PartyBuffs = L{

        },
        SelfBuffs = L{
            Spell.new("Temper", L{}, nil, nil, L{}),
            Spell.new("Crusade", L{}, nil, nil, L{}),
            Spell.new("Refresh", L{}, nil, nil, L{}),
            Spell.new("Regen IV", L{}, nil, nil, L{}),
            Spell.new("Shell V", L{}, nil, nil, L{}),
            Spell.new("Phalanx", L{}, nil, nil, L{})
        },
        JobAbilities = L{
            JobAbility.new('Swordplay', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Flash', L{}, L{})
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(30), HasRunesCondition.new(3)}, JobAbility.new("Vivacious Pulse", L{}, L{}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3)}, JobAbility.new("Valiance", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3)}, JobAbility.new("Vallation", L{}, L{}), "Self", L{}),
            }
        },
    }
}