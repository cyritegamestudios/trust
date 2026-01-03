-- Settings file for WHM
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
        StatusRemovalSettings = {
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, Spell.new("Curaga", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, Spell.new("Cure", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"curse", "doom", "doomed"}, 1), "Self")}, Spell.new("Cursna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"curse", "doom", "doomed"}, 1), "Ally")}, Spell.new("Cursna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"petrification"}, 1), "Self")}, Spell.new("Stona", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"petrification"}, 1), "Ally")}, Spell.new("Stona", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Self")}, Spell.new("Erase", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Ally")}, Spell.new("Erase", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Afflatus Misery"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"curse","disease","poison","paralysis","blindness","Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Self") }, Spell.new("Esuna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Self")}, Spell.new("Paralyna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Ally")}, Spell.new("Paralyna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Self")}, Spell.new("Silena", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Ally"), GambitCondition.new(JobCondition.new(L{"WHM", "RDM", "PLD", "BRD", "BLU", "SCH", "RUN", "BLM", "NIN", "SMN", "GEO", "DRK"}), "Ally")}, Spell.new("Silena", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Self")}, Spell.new("Poisona", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Ally")}, Spell.new("Poisona", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Self")}, Spell.new("Viruna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Ally")}, Spell.new("Viruna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Self")}, Spell.new("Blindna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Ally")}, Spell.new("Blindna", L{}, L{}, nil, L{}), "Ally", L{}, true),
            }
        },
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Self")}, Spell.new("Curaga IV", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 75, 3), "Self")}, Spell.new("Curaga III", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Ally")}, Spell.new("Curaga IV", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 75, 3), "Ally")}, Spell.new("Curaga III", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Self")}, Spell.new("Cure V", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 75), "Self")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Ally")}, Spell.new("Cure V", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 75), "Ally")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Ally", L{}, true)
            },
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
            Blacklist = L{

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
