-- Settings file for RUN
return {
    Version = 1,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Crusade", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Phalanx", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Buff.new("Refresh", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Shell V", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{InBattleCondition.new()}, JobAbility.new("Swordplay", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{InBattleCondition.new()}, Buff.new("Foil", L{}, L{}, nil, L{}), "Self", L{"Buffs"})
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
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(30), HasRunesCondition.new(3)}, JobAbility.new("Vivacious Pulse", L{}, L{}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("RUN")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"Food"}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3), MainJobCondition.new("RUN")}, JobAbility.new("Valiance", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(3), MainJobCondition.new("RUN")}, JobAbility.new("Vallation", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(2), NotCondition.new(L{MainJobCondition.new("RUN")})}, JobAbility.new("Valiance", L{}, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Valiance", "Vallation"}, 1)}), HasRunesCondition.new(2), NotCondition.new(L{MainJobCondition.new("RUN")})}, JobAbility.new("Vallation", L{}), "Self", L{"Buffs"})
            },
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