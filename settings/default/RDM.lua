-- Settings file for RDM
return {
    Version = 2,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 0.5,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, JobAbility.new("Composure", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Haste", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self")}, Buff.new("Temper", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self"), GambitCondition.new(MainJobCondition.new("RDM"), "Self")}, Spell.new("Enblizzard", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{ModeCondition.new("AutoMagicBurstMode", "Off")}), "Self")}, Spell.new("Gain-INT", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoMagicBurstMode", "Off"), "Self")}, Spell.new("Gain-STR", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(MainJobCondition.new("RDM"), "Self")}, Buff.new("Protect", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(MainJobCondition.new("RDM"), "Self")}, Buff.new("Shell", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"WAR", "NIN", "BST", "GEO", "SCH", "DRK", "DRG", "PUP", "BLU", "BLM", "THF", "PLD", "BRD", "SAM", "MNK", "RUN", "COR", "DNC", "RNG"}), "Ally")}, Buff.new("Haste", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"DRK", "PLD", "BLU", "BLM", "BRD", "GEO", "SMN", "WHM", "RUN"}), "Ally")}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(InBattleCondition.new(), "Ally"), GambitCondition.new(JobCondition.new(L{"NIN", "DNC", "GEO", "DRK", "SAM", "COR", "RNG", "PLD", "BRD", "WAR", "PUP", "DRG", "MNK", "RUN", "THF", "BST", "BLU"}), "Ally")}, Spell.new("Phalanx II", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
            }
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{GambitCondition.new(MaxManaPointsPercentCondition.new(20), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("weakness")}), "Self"), GambitCondition.new(ModeCondition.new("AutoConvertMode", "Auto"), "Self"), GambitCondition.new(JobAbilityRecastReadyCondition.new('Convert'), "Self")}, Spell.new("Cure IV", L{ 'Convert'}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(NotCondition.new(L{HasDebuffCondition.new("Evasion Down")}), "Enemy"), GambitCondition.new(MeleeAccuracyCondition.new(75, "<="), "Self"), GambitCondition.new(MainJobCondition.new("RDM"), "Self"), GambitCondition.new(NumResistsCondition.new("Distract", "<", 3), "Enemy"), GambitCondition.new(NumResistsCondition.new("Distract II", "<", 3), "Enemy"), GambitCondition.new(NumResistsCondition.new("Distract III", "<", 3), "Enemy")}, Spell.new("Distract III", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("RDM"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        ReactionSettings = {
            Gambits = L{
            }
        },
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Self")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Ally")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Ally", L{}, true),
            },
            MinNumAOETargets = 3,
            Delay = 2
        },
        StatusRemovalSettings = {
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, Spell.new("Cure", L{}, L{}, nil, L{}), "Ally", L{}, true),
            }
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
            Blacklist = L{

            },
            Distance = 20,
            MaxNumTargets = 1,
        },
        TargetSettings = {
            Retry = false
        },
        GearSwapSettings = {
            Enabled = true,
            Language = "en"
        },
    }
}