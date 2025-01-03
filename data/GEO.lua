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
            Spells = L{
                Spell.new('Aspir III'),
                Spell.new('Thunder V'),
                Spell.new('Thunder IV'),
                Spell.new('Thundara III'),
                Spell.new('Blizzard V'),
                Spell.new('Blizzard IV'),
                Spell.new('Blizzara III'),
                Spell.new('Fire V'),
                Spell.new('Fire IV'),
                Spell.new('Fira III'),
                Spell.new('Aero V'),
                Spell.new('Aero IV'),
                Spell.new('Aera III'),
                Spell.new('Water V'),
                Spell.new('Water IV'),
                Spell.new('Watera III'),
                Spell.new('Stone V'),
                Spell.new('Stone IV'),
                Spell.new('Stonera III'),
            },
            JobAbilities = L{
                JobAbility.new("Theurgic Focus", L{}, L{}),
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
            Abilities = L{
                Spell.new("Stone", L{}, L{})
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
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("GEO")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}
