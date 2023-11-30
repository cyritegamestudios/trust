-- Settings file for WAR
return {
    Version = 1,
    Default = {
        Skillchains = {
            spamws = L{
                "Impulse Drive",
                "Upheaval",
                "Savage Blade",
                "Judgment"
            },
            starterws = L{
                "Full Break"
            },
            defaultws = L{
                "Full Break",
                "King's Justice",
                "Upheaval",
                "Ukko's Fury",
                "Savage Blade",
                "Impulse Drive"
            },
            preferws = L{
                "King's Justice",
                "Steel Cyclone",
                "Upheaval",
                "Savage Blade",
                "Full Break",
                "Impulse Drive"
            },
            cleavews = L{
                "Fell Cleave"
            },
            amws = "King's Justice",
            tpws = L{

            }
        },
        JobAbilities = L{
            JobAbility.new('Berserk', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Aggressor', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Warcry', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Restraint', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Blood Rage', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Retaliation', L{}, L{}, nil),
        }
    }
}