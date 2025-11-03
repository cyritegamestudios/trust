-- Settings file for DNC
return {
    Version = 1,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 0.5,
        },
        CureSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 65, 3), "Self")}, JobAbility.new("Divine Waltz II"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(ClusterHitPointsPercentRangeCondition.new(1, 72, 3), "Self")}, JobAbility.new("Divine Waltz"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Self")}, JobAbility.new("Curing Waltz V"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Self")}, JobAbility.new("Curing Waltz IV"), "Self", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Self")}, JobAbility.new("Curing Waltz III"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 60), "Ally")}, JobAbility.new("Curing Waltz V"), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 65), "Ally")}, JobAbility.new("Curing Waltz IV"), "Ally", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HitPointsPercentRangeCondition.new(1, 72), "Ally")}, JobAbility.new("Curing Waltz III"), "Ally", L{}, true)
            },
            Delay = 2,
            MinNumAOETargets = 3
        },
        StatusRemovalSettings = {
            Gambits = L{
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"sleep"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"curse"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"curse"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"Accuracy Down", "addle", "AGI Down", "Attack Down", "bind", "Bio", "Burn", "Choke", "CHR Down", "Defense Down", "DEX Down", "Dia", "Drown", "Elegy", "Evasion Down", "Frost", "Inhibit TP", "INT Down", "Magic Acc. Down", "Magic Atk. Down", "Magic Def. Down", "Magic Evasion Down", "Max HP Down", "Max MP Down", "Max TP Down", "MND Down", "Nocturne", "Rasp", "Requiem", "Shock", "slow", "STR Down", "VIT Down", "weight", "Flash"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"paralysis"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"silence"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"poison"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"disease"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
                Gambit.new("Self", L{GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Self")}, JobAbility.new("Healing Waltz"), "Self", L{}, true),
                Gambit.new("Ally", L{GambitCondition.new(HasBuffsCondition.new(L{"blindness"}, 1), "Ally")}, JobAbility.new("Healing Waltz"), "Ally", L{}, true),
            }
        },
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Haste Samba", L{}, L{}), "Self", L{"Buffs"})
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
                Gambit.new("Enemy", L{}, JobAbility.new("Animated Flourish", L{}, L{}), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, RangedAttack.new(), "Enemy", L{"Pulling"}),
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
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Finishing Move (6+)")}), "Self")}, JobAbility.new("No Foot Rise", L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(MaxTacticalPointsCondition.new(900), "Self"), GambitCondition.new(HasBuffsCondition.new(L{"Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1), "Self")}, JobAbility.new("Reverse Flourish", L{}, L{}), "Self", L{}),
            },
            Gambits = L{
                Gambit.new("Enemy", L{GambitCondition.new(HasBuffCondition.new("Presto"), "Self"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Box Step", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{GambitCondition.new(HasDazeCondition.new("Sluggish Daze", 5, "<"), "Enemy"), GambitCondition.new(InBattleCondition.new(), "Self")}, JobAbility.new("Presto", L{}, L{}), "Enemy", L{}),
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("DNC"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
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