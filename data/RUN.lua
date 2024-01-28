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
        }
    }
}