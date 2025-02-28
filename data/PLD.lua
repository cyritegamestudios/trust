-- Settings file for PLD
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Crusade", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Reprisal", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Protect V", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, JobAbility.new("Majesty", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{StatusCondition.new("Engaged", 6, ">=")}, JobAbility.new("Rampart", L{}), "Self", L{"Buffs"})
            }
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1000,
                Emergency = 25,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 400
            },
            Delay = 2,
            StatusRemovals = {
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
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
            JobAbilities = L{

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
            Gambits = L{
                Gambit.new("Ally", L{MaxHitPointsPercentCondition.new(80), InBattleCondition.new()}, JobAbility.new("Cover", L{}, L{}), "Ally", L{}),
                Gambit.new("Enemy", L{InBattleCondition.new()}, JobAbility.new("Shield Bash", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{MinTacticalPointsCondition.new(2000), MaxManaPointsPercentCondition.new(30)}, JobAbility.new("Chivalry", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(25), InBattleCondition.new()}, JobAbility.new("Sentinel", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("PLD")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"Food"})
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