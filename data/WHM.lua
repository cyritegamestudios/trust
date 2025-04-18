-- Settings file for WHM
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Buff.new("Haste", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Reraise", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, JobAbility.new("Afflatus Solace", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Protectra", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Shellra", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Boost-STR", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(MainJobCondition.new("WHM"), "Self")}, Spell.new("Auspice", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"WAR", "MNK", "THF", "PLD", "DRK", "SAM", "DRG", "NIN", "PUP", "COR", "DNC", "BLU", "RUN", "BLM", "BRD", "BST"}), "Ally")}, Buff.new("Haste", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}), "Ally")}, Buff.new("Shell", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}), "Ally")}, Buff.new("Protect", L{}, L{}, nil, L{}), "Ally", L{"Buffs"})
            }
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1500,
                Emergency = 40,
                Default = 78,
                ["Cure III"] = 600,
                ["Curaga II"] = 600,
                ["Cure II"] = 0,
                ["Curaga III"] = 900,
                Curaga = 0
            },
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3,
            Overcure = false
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Holy II", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Holy", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Banish III", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
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
        GambitSettings = {
            Default = L{
                Gambit.new("Ally", L{GambitCondition.new(MaxManaPointsPercentCondition.new(20), "Ally"), GambitCondition.new(MaxDistanceCondition.new(10), "Ally"), GambitCondition.new(JobCondition.new(L{"SCH", "DRK", "WHM", "SMN", "GEO", "PLD", "BLM", "BLU", "RDM", "BRD", "RUN"}), "Ally")}, JobAbility.new("Devotion", L{}, L{}), "Ally", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(CombatSkillsCondition.new(L{"Club"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Mystic Boon", L{}), "Self", L{"Weaponskill"}),
                Gambit.new("Self", L{GambitCondition.new(CombatSkillsCondition.new(L{"Club"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Dagan", L{}), "Self", L{"Weaponskill"}),
                Gambit.new("Self", L{GambitCondition.new(CombatSkillsCondition.new(L{"Club"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Moonlight", L{}), "Self", L{"Weaponskill"}),
                Gambit.new("Enemy", L{GambitCondition.new(CombatSkillsCondition.new(L{"Staff"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Spirit Taker", L{}), "Self", L{"Weaponskill"}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("WHM"), "Self")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"food"}),
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
