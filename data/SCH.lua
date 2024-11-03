-- Settings file for SCH
return {
    Version = 2,
    Default = {
        LightArts = {
            JobAbilities = L{
                JobAbility.new('Light Arts', L{}, L{}, nil),
            },
            PartyBuffs = L{
                Spell.new("Adloquium", L{}, L{"WAR", "DRK", "DRG"}, nil, L{})
            },
            SelfBuffs = L{
                Buff.new("Protect", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">="), MainJobCondition.new("SCH")}),
                Buff.new("Shell", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">="), MainJobCondition.new("SCH")}),
                Buff.new("Regen", L{"Accession", "Perpetuance"}, L{}, nil, L{StrategemCountCondition.new(2, ">="), MainJobCondition.new("SCH")}),
                Spell.new("Phalanx", L{"Accession", "Perpetuance"}, nil, nil, L{StrategemCountCondition.new(2, ">="), MainJobCondition.new("SCH")}),
                Buff.new("Aurorastorm", L{}, L{}, nil, L{NotCondition.new(L{MainJobCondition.new("SCH")})}),
                Spell.new("Aurorastorm II", L{}, L{}, nil, L{}),
            }
        },
        StrategemCooldown = 33,
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1200,
                Emergency = 25,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 500
            },
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            JobAbilities = L{
                JobAbility.new('Ebullience', L{StrategemCountCondition.new(1, ">=")}),
            },
            Spells = L{
                Spell.new('Thunder V'),
                Spell.new('Thunder IV'),
                Spell.new('Blizzard V'),
                Spell.new('Blizzard IV'),
                Spell.new('Fire V'),
                Spell.new('Fire IV'),
                Spell.new('Aero V'),
                Spell.new('Aero IV'),
                Spell.new('Water V'),
                Spell.new('Water IV'),
                Spell.new('Stone V'),
                Spell.new('Stone IV'),
            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Stone', L{}, L{})
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
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Sublimation: Activated", "Sublimation: Complete", "Refresh"}, 1)})}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasBuffsCondition.new(L{"Sublimation: Complete"}, 1), MaxManaPointsPercentCondition.new(30)}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Addendum: Black")}), HasBuffCondition.new("Dark Arts"), StrategemCountCondition.new(1, ">=")}, JobAbility.new("Addendum: Black", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Addendum: White")}), HasBuffCondition.new("Light Arts"), StrategemCountCondition.new(1, ">=")}, JobAbility.new("Addendum: White", L{}, L{}), "Self", L{})
            },
            Gambits = L{

            },
        },
        DarkArts = {
            JobAbilities = L{
                JobAbility.new('Dark Arts', L{}, L{}, nil),
            },
            PartyBuffs = L{

            },
            SelfBuffs = L{
                Spell.new("Klimaform", L{}, nil, nil, L{})
            },
        }
    }
}