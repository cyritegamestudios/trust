-- Settings file for WHM
return {
    Version = 2,
    Default = {
        SelfBuffs = L{
            JobAbility.new('Afflatus Solace', L{}, L{}, nil),
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
        PartyBuffs = L{
            Buff.new("Haste", L{}, L{}, nil, L{JobCondition.new(L{"WAR", "MNK", "THF", "PLD", "DRK", "SAM", "DRG", "NIN", "PUP", "COR", "DNC", "BLU", "RUN", "BLM", "BRD", "BST"})}),
            Buff.new("Protect", L{}, L{}, nil, L{JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"})}),
            Buff.new("Shell", L{}, L{}, nil, L{JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"})})
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
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
        DebuffSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Debuff.new("Dia", L{}, L{}, L{}), "Enemy", L{"Debuffs"})
            }
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
        TargetSettings = {
            Retry = true
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Ally", L{MaxManaPointsPercentCondition.new(20), MaxDistanceCondition.new(10), JobCondition.new(L{"SCH", "DRK", "WHM", "SMN", "GEO", "PLD", "BLM", "BLU", "RDM", "BRD", "RUN"})}, JobAbility.new("Devotion", L{}, L{}), "Ally", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("WHM")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}
