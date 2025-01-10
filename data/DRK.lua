-- Settings file for DRK
return {
    Version = 1,
    Default = {
        DebuffSettings = {
            Gambits = L{

            }
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Last Resort", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Scarlet Delirium", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Idle", 2, ">=")}, Buff.new("Endark", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Absorb-STR", L{}, L{}, "bt", L{}), "Self", L{"Buffs"})
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new('Absorb-STR', L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Spell.new('Absorb-DEX', L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Spell.new('Stone', L{}, L{}), "Enemy", L{"Pulling"}),
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
            Retry = false,
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Spells = L{
                Spell.new("Drain III", L{}, L{}, nil, L{}),
                Spell.new("Drain II", L{}, L{}, nil, L{}),
            },
            JobAbilities = L{
                JobAbility.new("Nether Void"),
                JobAbility.new("Dark Seal"),
            },
            Blacklist = L{

            },
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Enemy", L{MeleeAccuracyCondition.new(75, "<="), MainJobCondition.new("DRK")},  Spell.new("Absorb-ACC", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasBuffCondition.new("Max HP Boost"), StatusCondition.new('Idle', 2, ">="), NotCondition.new(L{HasBuffCondition.new("Dread Spikes")})},  Spell.new("Dread Spikes", L{}, L{}), "Self"),
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("DRK")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}
