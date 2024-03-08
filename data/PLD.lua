-- Settings file for PLD
return {
    Version = 1,
    Default = {
        AutoFood="Miso Ramen",
        SelfBuffs = L{
            Spell.new("Phalanx", L{}, nil, nil, L{}),
            Spell.new("Protect V", L{}, nil, nil, L{})
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1000,
                Emergency = 25,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 400
            },
            Delay = 2,
            StatusRemovals = {
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
        },
        JobAbilities = L{
            JobAbility.new('Majesty', L{InBattleCondition.new()}),
        },
        PartyBuffs = L{

        },
    }
}