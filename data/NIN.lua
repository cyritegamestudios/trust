-- Settings file for NIN
return {
    Version = 2,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 1.5,
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, Spell.new("Utsusemi: San", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Utsusemi: Ni", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Utsusemi: Ichi", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Kakka: Ichi", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, Spell.new("Myoshu: Ichi", L{}, L{}, nil, L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self")}, JobAbility.new("Yonin", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{GambitCondition.new(StatusCondition.new("Engaged", 2, ">="), "Self")}, JobAbility.new("Issekigan", L{}, L{}), "Self", L{"Buffs"})
            }
        },
        DebuffSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Jubaku: Ni", L{}, L{}), "Enemy", L{"Debuffs"})
            }
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 0,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Raiton: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Raiton: Ni", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Hyoton: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Hyoton: Ni", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Katon: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Katon: Ni", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Huton: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Huton: Ni", L{}, L{}, nil, L{}, nil, true), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Suiton: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Suiton: Ni", L{}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Doton: San", L{"Futae"}, L{}, nil, L{}, nil), "Enemy", L{}),
                Gambit.new("Enemy", L{}, Spell.new("Doton: Ni", L{}, L{}, nil, L{}, nil), "Enemy", L{}),
            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(ItemCountCondition.new("Chonofuda", 1, ">="), "Self")}, Spell.new("Jubaku: Ni", L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
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
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("NIN"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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