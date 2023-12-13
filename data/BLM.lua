-- Settings file for BLM
return {
    Version = 1,
    Default = {
        AutoFood="Tropical Crepe",
        Skillchains = {
            spamws = L{
                "Vidohunir"
            },
            starterws = L{
                "Shattersoul"
            },
            defaultws = L{
                "Vidohunir"
            },
            preferws = L{
                "Vidohunir"
            },
            cleavews = L{
                "Cataclysm",
            },
            amws = "Vidohunir",
            tpws = L{
            }
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        Debuffs = L{
            Spell.new("Burn", L{}, nil, nil, L{})
        },
        JobAbilities = L{
            JobAbility.new('Mana Wall', L{}, L{}, nil),
        }
    }
}