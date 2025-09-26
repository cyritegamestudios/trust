-- Settings file for RUN
return {
    Version = 1,
    Default = {
        CombatSettings = {
            Distance = 2,
            MirrorDistance = 1.5,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Crusade", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Shell V", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Swordplay", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self")}, Buff.new("Foil", L{}, L{}, nil, L{}), "Self", L{"Buffs"})
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Flash", L{}, L{}), "Enemy", L{"Pulling"}),
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
                Gambit.new("Self", L{GambitCondition.new(MaxHitPointsPercentCondition.new(30), "Self"), GambitCondition.new(HasRunesCondition.new(3), "Self")}, JobAbility.new("Vivacious Pulse", L{}, L{}), "Self", L{}),
                Gambit.new("Enemy", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, Spell.new("Flash", L{}, L{}, nil, L{}), "Enemy", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoTankMode", "Auto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, Spell.new("Foil", L{}, L{}, nil, L{}), "Self", L{}),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("RUN"), "Self")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"food"}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), "Self"), GambitCondition.new(HasRunesCondition.new(3), "Self"), GambitCondition.new(MainJobCondition.new("RUN"), "Self")}, JobAbility.new("Valiance", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), "Self"), GambitCondition.new(HasRunesCondition.new(3), "Self"), GambitCondition.new(MainJobCondition.new("RUN"), "Self")}, JobAbility.new("Vallation", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), "Self"), GambitCondition.new(HasRunesCondition.new(2), "Self"), GambitCondition.new(NotCondition.new(L{MainJobCondition.new("RUN")}), "Self")}, JobAbility.new("Valiance", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), "Self"), GambitCondition.new(HasRunesCondition.new(2), "Self"), GambitCondition.new(NotCondition.new(L{MainJobCondition.new("RUN")}), "Self")}, JobAbility.new("Vallation", L{}, L{}), "Self", L{"Buffs"}),
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