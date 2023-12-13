-- Settings file for COR
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Savage Blade"
            },
            starterws = L{
                "Leaden Salute"
            },
            defaultws = L{
                "Leaden Salute",
                "Savage Blade"
            },
            preferws = L{
                "Leaden Salute",
                "Last Stand",
                "Savage Blade"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            amws = "Leaden Salute",
            tpws = L{
            }
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        Roll1 = Roll.new("Chaos Roll", true),
        Roll2 = Roll.new("Samurai Roll", false)
    }
}