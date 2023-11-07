-- Settings file for RDM
return {
    Default = {
        SelfBuffs = L{
            Buff.new("Refresh", L{}, L{}, nil, L{}),
            Buff.new("Haste", L{}, L{}, nil, L{}),
            Buff.new("Temper", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Enblizzard", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Gain-INT", L{}, L{}, nil, L{IdleCondition.new()}),
            Spell.new("Gain-STR", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Phalanx", L{}, nil, nil, L{}),
            Buff.new("Protect", L{}, L{}, nil, L{}),
            Buff.new("Shell", L{}, L{}, nil, L{})
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1500,
                Emergency = 35,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 600
            },
            Delay = 2
        },
        JobAbilities = L{
            "Composure"
        },
        PartyBuffs = L{
            Buff.new("Refresh", L{}, L{"DRK", "PUP", "PLD", "BLU", "BLM", "BRD", "GEO", "SMN", "WHM", "RUN"}, nil, L{}),
            Buff.new("Haste", L{}, L{"WAR", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "RUN", "MNK", "THF", "BST", "NIN", "DNC", "DRK", "GEO", "SCH", "BLM"}, nil, L{}),
            Buff.new("Haste", L{}, L{"COR"}, nil, L{InBattleCondition.new()}),
            Buff.new("Flurry", L{}, L{"RNG", "COR"}, nil, L{IdleCondition.new()}),
            Spell.new("Phalanx II", L{}, L{"WAR", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "RUN", "MNK", "THF", "BST", "NIN", "DNC", "DRK", "GEO"}, nil, L{InBattleCondition.new()})
        },
        AutoFood = "Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Savage Blade",
                "Black Halo"
            },
            starterws = L{
                "Death Blossom",
                "Savage Blade"
            },
            defaultws = L{
                "Savage Blade",
                "Seraph Blade",
                "Death Blossom",
                "Black Halo"
            },
            preferws = L{
                "Flat Blade",
                "Death Blossom",
                "Savage Blade",
                "Black Halo",
                "Realmrazer"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            amws = "Death Blossom",
            tpws = L{
                "Savage Blade"
            }
        },
        Debuffs = L{
            Debuff.new("Distract", L{})
        }
    }
}