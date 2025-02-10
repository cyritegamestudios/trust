-- Settings file for WHM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Buff.new("Haste", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Reraise", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, JobAbility.new("Afflatus Solace", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Protectra", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Shellra", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Boost-STR", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{MainJobCondition.new("WHM")}, Spell.new("Auspice", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"WAR", "MNK", "THF", "PLD", "DRK", "SAM", "DRG", "NIN", "PUP", "COR", "DNC", "BLU", "RUN", "BLM", "BRD", "BST"})}, Buff.new("Haste", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"})}, Buff.new("Shell", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"})}, Buff.new("Protect", L{}, L{}, nil, L{}), "Ally", L{"Buffs"})
            }
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
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Holy II", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Holy", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Banish III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
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
            Gambits = L{
                Gambit.new("Enemy", L{}, Debuff.new("Dia", L{}, L{}), "Enemy", L{"Pulling"}),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20,
            MaxNumTargets = 1,
        },
        TargetSettings = {
            Retry = false
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Ally", L{MaxManaPointsPercentCondition.new(20), MaxDistanceCondition.new(10), JobCondition.new(L{"SCH", "DRK", "WHM", "SMN", "GEO", "PLD", "BLM", "BLU", "RDM", "BRD", "RUN"})}, JobAbility.new("Devotion", L{}, L{}), "Ally", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("WHM")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"Food"})
            }
        },
        ReactionSettings = {
            Gambits = L{
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}
