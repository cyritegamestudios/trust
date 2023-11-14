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
        JobAbilities = L{
            JobAbility.new('Haste Samba', L{}, L{InBattleCondition.new()}, nil),
        }
    }
}