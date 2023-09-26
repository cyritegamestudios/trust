-- Settings file for BLU
return {
    Default = {
        Skillchains = {
            spamws = L{
                "Savage Blade",
                "Black Halo"
            },
            starterws = L{
                "Savage Blade"
            },
            defaultws = L{
                "Expiacion",
                "Savage Blade"
            },
            preferws = L{
                "Expiacion",
                "Savage Blade"
            },
            cleavews = L{

            },
            amws = "Expiacion",
            tpws = L{
                "Expiacion",
                "Savage Blade"
            }
        },
        SelfBuffs = L{
            Spell.new("Erratic Flutter", L{}, nil, nil, L{}),
            Spell.new("Cocoon", L{}, nil, nil, L{}),
            Spell.new("Barrier Tusk", L{}, nil, nil, L{}),
            Spell.new("Nat. Meditation", L{}, nil, nil, L{}),
            Spell.new("Occultation", L{}, nil, nil, L{}),
            Spell.new("Mighty Guard", L{"Unbridled Learning"}, nil, nil, L{})
        }
    }
}