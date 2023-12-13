-- Settings file for DNC
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Rudra's Storm",
                "Asuran Fists"
            },
            starterws = L{
                "Shark Bite"
            },
            defaultws = L{
                "Evisceration",
                "Asuran Fists"
            },
            cleavews = L{
                "Aeolian Edge",
            },
            preferws = L{
                "Rudra's Storm",
                "Pyrrhic Kleos",
                "Asuran Fists"
            },
            amws = "Pyrrhic Kleos",
            tpws = L{
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
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Haste Samba', L{InBattleCondition.new()}),
        }
    }
}