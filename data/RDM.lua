-- Settings file for RDM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, JobAbility.new("Composure", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Haste", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{InBattleCondition.new()}, Buff.new("Temper", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{InBattleCondition.new(), MainJobCondition.new("RDM")}, Spell.new("Enblizzard", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{NotCondition.new(L{ModeCondition.new("AutoMagicBurstMode", "Off")})}, Spell.new("Gain-INT", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{ModeCondition.new("AutoMagicBurstMode", "Off")}, Spell.new("Gain-STR", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{MainJobCondition.new("RDM")}, Buff.new("Protect", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{MainJobCondition.new("RDM")}, Buff.new("Shell", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"WAR", "NIN", "BST", "GEO", "SCH", "DRK", "DRG", "PUP", "BLU", "BLM", "THF", "PLD", "BRD", "SAM", "MNK", "RUN", "COR", "DNC", "RNG"})}, Buff.new("Haste", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{JobCondition.new(L{"DRK", "PLD", "BLU", "BLM", "BRD", "GEO", "SMN", "WHM", "RUN"})}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{InBattleCondition.new(), JobCondition.new(L{"NIN", "DNC", "GEO", "DRK", "SAM", "COR", "RNG", "PLD", "BRD", "WAR", "PUP", "DRG", "MNK", "RUN", "THF", "BST", "BLU"})}, Spell.new("Phalanx II", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
            }
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MaxManaPointsPercentCondition.new(80), NotCondition.new(L{HasBuffCondition.new("weakness")}), ModeCondition.new("AutoConvertMode", "Auto"), JobAbilityRecastReadyCondition.new('Convert')}, Spell.new("Cure IV", L{ 'Convert'}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Enemy", L{MeleeAccuracyCondition.new(75, "<="), MainJobCondition.new("RDM"), NumResistsCondition.new("Distract", "<", 3), NumResistsCondition.new("Distract II", "<", 3), NumResistsCondition.new("Distract III", "<", 3)}, Spell.new("Distract III", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("RDM")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"Food"})
            }
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1500,
                Emergency = 35,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 600
            },
            MinNumAOETargets = 3,
            Delay = 2
        },
        NukeSettings = {
            MinNumMobsToCleave = 2,
            MinManaPointsPercent = 40,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Thunder V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Thunder III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Blizzard III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Fire III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Aero III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Water III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone V", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone IV", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{}, Spell.new("Stone III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Nukes"}),
            },
            Delay = 4,
            JobAbilities = L{

            },
            Blacklist = L{

            }
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
        GearSwapSettings = {
            Enabled = true
        },
    }
}