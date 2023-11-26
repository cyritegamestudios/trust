-- Settings file for PLD
return {
    Version = 1,
    Default = {
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
            }
        },
        JobAbilities = L{
            JobAbility.new('Majesty', L{InBattleCondition.new()}),
        },
        PartyBuffs = L{

        },
        Skillchains = {
            spamws = L{
                "Savage Blade",
                "Torcleaver"
            },
            starterws = L{
                "Red Lotus Blade"
            },
            defaultws = L{
                "Savage Blade",
                "Torcleaver"
            },
            preferws = L{
                "Red Lotus Blade",
                "Torcleaver"
            },
            cleavews = L{
                "Circle Blade"
            },
            amws = "Torcleaver",
            tpws = L{

            }
        }
    }
}