-- Settings file for DRK
return {
    Version = 1,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 0.5,
        },
        DebuffSettings = {
            Gambits = L{

            }
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Last Resort", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 2, ">=")}, JobAbility.new("Scarlet Delirium", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Idle", 2, ">=")}, Buff.new("Endark", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Absorb-STR", L{}, L{}, "bt", L{}), "Self", L{"Buffs"})
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new('Absorb-STR', L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Spell.new('Absorb-DEX', L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Spell.new('Stone', L{}, L{}), "Enemy", L{"Pulling"}),
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
            Retry = false,
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Max HP Boost")}), "Self")}, Spell.new("Drain III", L{"Dark Seal", "Nether Void"}, L{}, nil, L{}, nil, false), "Enemy", L{"Nukes"}),
                Gambit.new("Enemy", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Max HP Boost")}), "Self")}, Spell.new("Drain II", L{"Dark Seal", "Nether Void"}, L{}, nil, L{}, nil, false), "Enemy", L{"Nukes"}),
            },
            Blacklist = L{

            },
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Enemy", L{GambitCondition.new(CombatSkillsCondition.new(L{"Scythe"}), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(25), "Self"), GambitCondition.new(MinTacticalPointsCondition.new(1000), "Self"), GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self"), GambitCondition.new(ModeCondition.new("AutoRestoreManaMode", "Auto"), "Self")}, WeaponSkill.new("Entropy", L{}), "Self", L{"Weaponskill"}),
            },
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(MeleeAccuracyCondition.new(75, "<="), "Self"), GambitCondition.new(MainJobCondition.new("DRK"), "Self")},  Spell.new("Absorb-ACC", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Max HP Boost"), "Self"), GambitCondition.new(StatusCondition.new('Idle', 2, ">="), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Dread Spikes")}), "Self")},  Spell.new("Dread Spikes", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("DRK"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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
