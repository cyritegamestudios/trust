-- Settings file for BLU
return {
    Version = 2,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 1.5,
        },
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
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Self")}, Spell.new("White Wind", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 75, 3), "Self")}, Spell.new("Healing Breeze", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, Spell.new("Magic Fruit", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 75), "Self")}, Spell.new("Wild Carrot", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, Spell.new("Magic Fruit", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 75), "Ally")}, Spell.new("Wild Carrot", L{}, L{}, nil, L{}), "Ally", L{}, true),
            },
            MinNumAOETargets = 3,
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
            Blacklist = L{

            },
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Enemy", L{GambitCondition.new(MaxManaPointsPercentCondition.new(25), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, Spell.new("Magic Hammer", L{}, L{}, nil, L{}), "Enemy", L{"Spell"}),
                Gambit.new("Enemy", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, Spell.new("Geist Wall", L{}, L{}, nil, L{}), "Enemy", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, Spell.new("Sheep Song", L{}, L{}, nil, L{}), "Enemy", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("BLU"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        ReactionSettings = {
            Gambits = L{
            }
        },
        GearSwapSettings = {
            Enabled = true,
            Language = "en"
        },

    }
}