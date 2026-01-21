-- Settings file for SCH
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
                Gambit.new("Self", L{}, Buff.new("Reraise", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StrategemCountCondition.new(1, ">="), "Self"), GambitCondition.new(MainJobCondition.new("SCH"), "Self")}, Buff.new("Protect", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StrategemCountCondition.new(1, ">="), "Self"), GambitCondition.new(MainJobCondition.new("SCH"), "Self")}, Buff.new("Shell", L{"Accession"}, L{}, nil, L{StrategemCountCondition.new(1, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StrategemCountCondition.new(2, ">="), "Self"), GambitCondition.new(MainJobCondition.new("SCH"), "Self")}, Buff.new("Regen", L{"Accession", "Perpetuance"}, L{}, nil, L{StrategemCountCondition.new(2, ">=")}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StrategemCountCondition.new(1, ">="), "Self"), GambitCondition.new(HasBuffsCondition.new(L{ 'Dark Arts', 'Addendum: Black' }, 1), "Self")}, Spell.new("Klimaform", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{ 'Light Arts', 'Addendum: White' }, 1), "Self")}, Spell.new("Aurorastorm II", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Ally", L{GambitCondition.new(JobCondition.new(L{"BLM", "RDM", "GEO"}), "Ally"), GambitCondition.new(NotCondition.new(L{IsAlterEgoCondition.new()}), "Ally")}, Spell.new("Thunderstorm II", L{}, L{}, nil, L{}), "Ally", L{"Buffs"}),
            }
        },
        StrategemCooldown = 33,
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Self")}, Spell.new("Cure IV", L{ "Accession" }, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 75, 3), "Self")}, Spell.new("Cure III", L{ "Accession" }, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Ally")}, Spell.new("Cure IV", L{ "Accession" }, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 75, 3), "Ally")}, Spell.new("Cure III", L{ "Accession" }, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Self")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Ally")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Ally", L{}, true),
            },
            Delay = 2,
            MinNumAOETargets = 3
        },
        StatusRemovalSettings = {
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, Spell.new("Cure", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"curse", "doom", "doomed"}, 1), "Self")}, Spell.new("Cursna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"curse", "doom", "doomed"}, 1), "Ally")}, Spell.new("Cursna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"petrification"}, 1), "Self")}, Spell.new("Stona", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"petrification"}, 1), "Ally")}, Spell.new("Stona", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Self")}, Spell.new("Erase", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Ally")}, Spell.new("Erase", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Self")}, Spell.new("Paralyna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Ally")}, Spell.new("Paralyna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Self")}, Spell.new("Silena", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Ally")}, Spell.new("Silena", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Self")}, Spell.new("Poisona", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Ally")}, Spell.new("Poisona", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Self")}, Spell.new("Viruna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Ally")}, Spell.new("Viruna", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Self")}, Spell.new("Blindna", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffCondition.new("Addendum: White"), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Ally")}, Spell.new("Blindna", L{}, L{}, nil, L{}), "Ally", L{}, true),
            }
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
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Sublimation: Activated", "Sublimation: Complete", "Refresh"}, 1)}), "Self"), GambitCondition.new(ModeCondition.new("AutoSublimationMode", "Auto"), "Self")}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"Sublimation: Complete"}, 1), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(30), "Self")}, JobAbility.new("Sublimation", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoArtsMode", "DarkArts"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Dark Arts", "Addendum: Black"}, 1)}), "Self")}, JobAbility.new("Dark Arts", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoArtsMode", "LightArts"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Light Arts", "Addendum: White"}, 1)}), "Self")}, JobAbility.new("Light Arts", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Addendum: Black")}), "Self"), GambitCondition.new(HasBuffCondition.new("Dark Arts"), "Self"), GambitCondition.new(StrategemCountCondition.new(1, ">="), "Self")}, JobAbility.new("Addendum: Black", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Addendum: White")}), "Self"), GambitCondition.new(HasBuffCondition.new("Light Arts"), "Self"), GambitCondition.new(StrategemCountCondition.new(1, ">="), "Self")}, JobAbility.new("Addendum: White", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(CombatSkillsCondition.new(L{"Staff"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Myrkr", L{}), "Self", L{"Weaponskill"}),
                Gambit.new("Enemy", L{GambitCondition.new(CombatSkillsCondition.new(L{"Staff"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(40), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Spirit Taker", L{}), "Self", L{"Weaponskill"}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("SCH"), "Self")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"food"}),
            },
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
