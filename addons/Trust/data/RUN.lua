-- Settings file for RUN
return {
    Default = {
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
        Skillchains = {
            spamws = L{
                "Dimidiation",
                "Savage Blade"
            },
            starterws = L{
                "Dimidiation"
            },
            defaultws = L{
                "Dimidiation",
                "Steel Cyclone"
            },
            preferws = L{
                "Dimidiation",
                "Savage Blade"
            },
            cleavews = L{

            },
            amws = "Dimidiation",
            tpws = L{

            }
        },
        JobAbilities = L{
            "Swordplay"
        }
    }
}