-- Settings file for BLU
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Barrier Tusk", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Cocoon", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Erratic Flutter", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Mighty Guard", L{"Unbridled Learning", "Diffusion"}, L{}, nil, L{}), "Self", L{}),
                Gambit.new("Self", L{}, Buff.new("Mighty Guard", L{"Unbridled Learning"}, L{}, nil, L{}), "Self", L{}),
                Gambit.new("Self", L{}, Spell.new("Nat. Meditation", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Occultation", L{}, L{}, nil, L{}), "Self", L{"Buffs"})
            }
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 600,
                Emergency = 40,
                Default = 65,
                ["Cure III"] = 400,
                ["Curaga III"] = 800,
                ["Cure II"] = 0,
                ["Curaga II"] = 400,
                Curaga = 0
            },
            MinNumAOETargets = 3,
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Glutinous Dart", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
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
        BlueMagicSettings = {
            SpellSets = {
                Default = BlueMagicSet.new(L{"White Wind", "Molting Plumage", "Thrashing Assault", "Fantod", "Erratic Flutter", "Tail Slap", "Paralyzing Triad", "Metallic Body", "Diffusion Ray", "Magic Fruit", "Embalming Earth", "Sudden Lunge", "Sinker Drill", "Cocoon", "Occultation", "Heavy Strike", "Nat. Meditation", "Empty Thrash", "Sickle Slash"})
            }
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 30,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Anvil Lightning", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Spectral Floe", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Searing Tempest", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Silent Storm", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Scouring Spate", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Entomb", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Tenebral Crush", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Blinding Fulgor", L{"Burst Affinity"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
            },
            JobAbilities = L{
            },
            Blacklist = L{

            },
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BLU")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"Food"})
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