-- Settings file for SAM
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Tachi: Fudo"
            },
            starterws = L{
                "Tachi: Ageha"
            },
            defaultws = L{
                "Tachi: Fudo"
            },
            preferws = L{
                "Tachi: Kasha",
                "Tachi: Shoha",
                "Tachi: Fudo"
            },
            cleavews = L{
                "Sonic Thrust",
            },
            amws = "Tachi: Rana",
            tpws = L{
            }
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Hasso', L{}, L{}, nil)
        }
    }
}