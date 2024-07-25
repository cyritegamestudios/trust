-- Settings file for DNC
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        CureSettings = {
            Thresholds = {
                Emergency = 40,
                Default = 78,
                ["Curing Waltz II"] = 0,
                ["Curing Waltz III"] = 600,
                ["Curing Waltz IV"] = 1500,
                ["Divine Waltz"] = 0,
                ["Divine Waltz II"] = 600,
            },
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Haste Samba', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                JobAbility.new("Animated Flourish", L{}, L{})
            },
            Distance = 20
        },
        GambitSettings = {
            Gambits = L{

            }
        },
    }
}