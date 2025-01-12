-- Settings file for SCH
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Buff.new("Reraise", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StrategemCountCondition.new(1, ">="), MainJobCondition.new("SCH")}, Buff.new("Protect", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StrategemCountCondition.new(1, ">="), MainJobCondition.new("SCH")}, Buff.new("Shell", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StrategemCountCondition.new(2, ">="), MainJobCondition.new("SCH")}, Buff.new("Regen", L{"Accession", "Perpetuance"}, L{}, nil, L{StrategemCountCondition.new(2, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StrategemCountCondition.new(1, ">="), HasBuffsCondition.new(L{ 'Dark Arts', 'Addendum: Black' }, 1)}, Spell.new("Klimaform", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{HasBuffsCondition.new(L{ 'Light Arts', 'Addendum: White' }, 1)}, Spell.new("Aurorastorm II", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"BLM", "RDM", "GEO"}), NotCondition.new(L{IsAlterEgoCondition.new()})}, Spell.new("Thunderstorm II", L{}, L{}, nil, L{}), "Ally", L{"Buffs"})
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
            GearswapCommand = "gs c set MagicBurstMode Single",
            JobAbilities = L{
            },
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Thunder V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone V", L{"Ebullience"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
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
                Gambit.new("Enemy", L{}, Spell.new("Stone", L{}, L{}), "Enemy", L{"Pulling"}),
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
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Sublimation: Activated", "Sublimation: Complete", "Refresh"}, 1)})}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasBuffsCondition.new(L{"Sublimation: Complete"}, 1), MaxManaPointsPercentCondition.new(30)}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{ModeCondition.new("AutoArtsMode", "DarkArts"), NotCondition.new(L{HasBuffsCondition.new(L{"Dark Arts", "Addendum: Black"}, 1)})}, JobAbility.new("Dark Arts", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{ModeCondition.new("AutoArtsMode", "LightArts"), NotCondition.new(L{HasBuffsCondition.new(L{"Light Arts", "Addendum: White"}, 1)})}, JobAbility.new("Light Arts", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Addendum: Black")}), HasBuffCondition.new("Dark Arts"), StrategemCountCondition.new(1, ">=")}, JobAbility.new("Addendum: Black", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Addendum: White")}), HasBuffCondition.new("Light Arts"), StrategemCountCondition.new(1, ">=")}, JobAbility.new("Addendum: White", L{}, L{}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("SCH")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"Food"})
            },
        },
        DarkArts = {
            BuffSettings = {
                Gambits = L{

                }
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}
