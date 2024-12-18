-- Settings file for DRK
return {
    Version = 1,
    Default = {
        SelfBuffs = L{
            Spell.new("Endark II", L{}, L{}, nil, L{IdleCondition.new()}),
            Spell.new("Absorb-STR", L{}, L{}, "bt", L{}),
            Spell.new("Absorb-DEX", L{}, L{}, "bt", L{}),
            JobAbility.new('Last Resort', L{InBattleCondition.new()}),
            JobAbility.new('Scarlet Delirium', L{InBattleCondition.new()}),
        },
        PartyBuffs = L{

        },
        Debuffs = L {

        },
        PullSettings = {
            Abilities = L{
                Spell.new('Absorb-STR', L{}, L{}),
                Spell.new('Absorb-DEX', L{}, L{}),
                Spell.new('Stone', L{}, L{})
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20,
            MaxNumMobs = 1,
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
                Gambit.new("Self", L{HasBuffCondition.new("Max HP Boost"), IdleCondition.new(), NotCondition.new(L{HasBuffCondition.new("Dread Spikes")})},  Spell.new("Dread Spikes", L{}, L{}), "Self"),
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
