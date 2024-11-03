-- Settings file for WHM
return {
    Version = 2,
    Default = {
        AutoFood = "Tropical Crepe",
        SelfBuffs = L{
            Buff.new("Haste", L{}, L{}, nil, L{}),
            Buff.new("Protectra", L{}, L{}, nil, L{}),
            Buff.new("Shellra", L{}, L{}, nil, L{}),
            Buff.new("Boost-STR", L{}, L{}, nil, L{}),
            Buff.new("Auspice", L{}, L{}, nil, L{}),
            Buff.new("Reraise", L{}, L{}, nil, L{})
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1500,
                Emergency = 40,
                Default = 78,
                ["Cure III"] = 600,
                ["Curaga II"] = 600,
                ["Cure II"] = 0,
                ["Curaga III"] = 900,
                Curaga = 0
            },
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3,
            Overcure = false
        },
        JobAbilities = L{
            JobAbility.new('Afflatus Solace', L{}, L{}, nil),
        },
        PartyBuffs = L{
            Buff.new("Haste", L{}, L{"WAR", "MNK", "THF", "PLD", "DRK", "SAM", "DRG", "NIN", "PUP", "COR", "DNC", "BLU", "RUN", "BLM", "BRD", "BST"}, nil, L{}),
            Buff.new("Protect", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{}),
            Buff.new("Shell", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{})
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            Spells = L{
                Spell.new('Holy II'),
                Spell.new('Holy'),
                Spell.new('Banish III'),
            },
            JobAbilities = L{

            },
            Blacklist = L{

            },
        },
        Debuffs = L{
            Spell.new("Dia II", L{}, nil, nil, L{})
        },
        PullSettings = {
            Abilities = L{
                Debuff.new('Dia', L{}, L{})
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Ally", L{MaxManaPointsPercentCondition.new(20), MaxDistanceCondition.new(10), JobCondition.new(L{"SCH", "DRK", "WHM", "SMN", "GEO", "PLD", "BLM", "BLU", "RDM", "BRD", "RUN"})}, JobAbility.new("Devotion", L{}, L{}), "Ally", L{}),
            },
            Gambits = L{

            }
        },
    }
}
