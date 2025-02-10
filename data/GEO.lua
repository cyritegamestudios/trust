-- Settings file for GEO
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
            }
        },
        NukeSettings = {
            Delay = 4,
            MinManaPointsPercent = 40,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Aspir III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Thundara III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzara III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Fire V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Fire IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Fira III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Aero V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Aero IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Aera III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Water V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Water IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Watera III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Stone V", L{"Theurgic Focus"}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Stone IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Stonera III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
            },
            JobAbilities = L{
            },
            Blacklist = L{

            },
        },
        Geomancy = {
            Indi = Spell.new("Indi-Fury", L{}, L{}, nil, L{}),
            Geo = Spell.new("Geo-Frailty", L{}, L{}, "bt", L{}),
            Entrust = Spell.new("Indi-Haste", L{ 'Entrust' }, nil, nil, L{ JobCondition.new(job_util.all_jobs()) })
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Gambits = L{
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
            Retry = false
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("GEO")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"Food"})
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
