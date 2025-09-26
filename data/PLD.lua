-- Settings file for PLD
return {
    Version = 2,
    Default = {
        CombatSettings = {
            Distance = 2,
            MirrorDistance = 1.5,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Crusade", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Reprisal", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Protect V", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, JobAbility.new("Majesty", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 6, ">="), "Self")}, JobAbility.new("Rampart", L{}), "Self", L{"Buffs"})
            }
        },
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Self")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Ally")}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Ally", L{}, true),
            },
            MinNumAOETargets = 3
        },
        StatusRemovalSettings = {
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, Spell.new("Cure", L{}, L{}, nil, L{}), "Ally", L{}, true),
            }
        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Holy II", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Holy", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Banish II", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
            },
            Blacklist = L{

            },
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Flash", L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Spell.new("Banish", L{}, L{}), "Enemy", L{"Pulling"}),
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
                Gambit.new("Enemy", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, Spell.new("Flash", L{}, L{}, nil, L{}), "Enemy", L{}),
            },
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(MaxHitPointsPercentCondition.new(80), "Ally"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Cover", L{}, L{}), "Ally", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Shield Bash", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(MinTacticalPointsCondition.new(2000), "Self"), GambitCondition.new(MaxManaPointsPercentCondition.new(30), "Self")}, JobAbility.new("Chivalry", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(MaxHitPointsPercentCondition.new(25), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Sentinel", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("PLD"), "Self")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"food"}),
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