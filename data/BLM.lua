-- Settings file for BLM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, JobAbility.new('Mana Wall', L{}, L{}, nil), "Self", L{"Buffs"}),
            }
        },
        DebuffSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Debuff.new("Burn", L{}, L{}, L{}), "Enemy", L{"Debuffs"})
            }
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Thunder VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thundaja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzaja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Firaja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aeroja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Waterja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stoneja", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone VI", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Comet", L{"Manawell"}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
            },
            JobAbilities = L{
                JobAbility.new("Ebullience", L{SubJobCondition.new('SCH'), StrategemCountCondition.new(1, ">=")}, L{}),
                JobAbility.new("Cascade", L{MinManaPointsPercentCondition.new(40), MinTacticalPointsCondition.new(1000)}, L{})
            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Burn", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Pulling"}),
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
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BLM")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"Food"})
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