-- Settings file for DNC
return {
    Version = 1,
    Default = {
        Skillchains = {
            spamws = L{
                "Rudra's Storm",
                "Asuran Fists"
            },
            starterws = L{
                "Shark Bite"
            },
            defaultws = L{
                "Rudra's Storm",
                "Pyrrhic Kleos",
                "Asuran Fists"
            },
            cleavews = L{

            },
            preferws = L{
                "Rudra's Storm",
                "Asuran Fists"
            },
            amws = "Pyrrhic Kleos",
            tpws = L{
                "Rudra's Storm",
                "Asuran Fists"
            }
        },
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
            }
        },
        JobAbilities = L{
            JobAbility.new('Saber Dance', L{}, L{InBattleCondition.new()}, nil),
            JobAbility.new('Haste Samba', L{}, L{InBattleCondition.new()}, nil),
        }
    }
}