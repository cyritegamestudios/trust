-- Settings file for GEO
return {
    Default = {
        SelfBuffs = L{

        },
        JobAbilities = L{

        },
        PartyBuffs = L{
            Spell.new("Indi-STR", L{"Entrust"}, L{"DRK", "SAM", "WAR", "MNK"}, nil, L{}),
            Spell.new("Indi-Fury", L{"Entrust"}, L{"RUN"}, nil, L{})
        },
        Skillchains = {
            spamws = L{
                "Black Halo"
            },
            starterws = L{

            },
            defaultws = L{
                "Black Halo"
            },
            preferws = L{
                "Black Halo"
            },
            cleavews = L{

            },
            amws = "Exudation",
            tpws = L{
                "Black Halo"
            }
        },
        Geomancy = {
            Indi = Spell.new("Indi-Acumen", L{}, L{}, nil, L{}),
            Geo = Spell.new("Geo-Malaise", L{}, L{}, "bt", L{})
        }
    }
}