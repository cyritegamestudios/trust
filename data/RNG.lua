-- Settings file for RNG
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Trueflight",
                "Jishnu's Radiance",
                "Savage Blade",
            },
            starterws = L{
                "Trueflight"
            },
            defaultws = L{
                "Last Stand",
                "Jishnu's Radiance",
            },
            preferws = L{
                "Trueflight",
                "Last Stand",
                "Wildfire",
            },
            cleavews = L{
                "Aeolian Edge"
            },
            amws = "Trueflight",
            tpws = L{

            }
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Velocity Shot', L{InBattleCondition.new()}),
        }
    }
}