-- Settings file for RNG
return {
    Version = 1,
    Default = {
        Skillchains = {
            spamws = L{
                "Trueflight"
            },
            starterws = L{
                "Trueflight"
            },
            defaultws = L{
                "Trueflight"
            },
            preferws = L{
                "Trueflight"
            },
            cleavews = L{

            },
            amws = "Trueflight",
            tpws = L{

            }
        },
        JobAbilities = L{
            JobAbility.new('Velocity Shot', L{InBattleCondition.new()}),
        }
    }
}