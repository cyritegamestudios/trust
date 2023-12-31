-- Settings file for GEO
return {
    Version = 2,
    Default = {
        AutoFood="Tropical Crepe",
        SelfBuffs = L{

        },
        JobAbilities = L{

        },
        PartyBuffs = L{
            Spell.new("Indi-STR", L{"Entrust"}, L{"DRK", "SAM", "WAR", "MNK"}, nil, L{}),
            Spell.new("Indi-Fury", L{"Entrust"}, L{"RUN"}, nil, L{})
        },
        NukeSettings = {
            Delay = 4,
            MinManaPointsPercent = 40,
            Spells = L{
                Spell.new('Aspir III'),
                Spell.new('Thunder V'),
                Spell.new('Thunder IV'),
                Spell.new('Thundara III'),
                Spell.new('Blizzard V'),
                Spell.new('Blizzard IV'),
                Spell.new('Blizzara III'),
                Spell.new('Fire V'),
                Spell.new('Fire IV'),
                Spell.new('Fira III'),
                Spell.new('Aero V'),
                Spell.new('Aero IV'),
                Spell.new('Aera III'),
                Spell.new('Water V'),
                Spell.new('Water IV'),
                Spell.new('Watera III'),
                Spell.new('Stone V'),
                Spell.new('Stone IV'),
                Spell.new('Stonera III'),
            },
            Blacklist = L{

            },
        },
        Skillchains = {
            spamws = L{
                "Black Halo"
            },
            starterws = L{
                "Shell Crusher"
            },
            defaultws = L{
                "Black Halo"
            },
            preferws = L{
                "Black Halo"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            amws = "Exudation",
            tpws = L{
            }
        },
        Geomancy = {
            Indi = Spell.new("Indi-Fury", L{}, L{}, nil, L{}),
            Geo = Spell.new("Geo-Frailty", L{}, L{}, "bt", L{})
        }
    }
}