-- Settings file for BST
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Cloudsplitter"
            },
            starterws = L{

            },
            defaultws = L{
                "Decimation",
                "Cloudsplitter"
            },
            petws = L{
                "Pentapeck"
            },
            preferws = L{
                "Decimation",
                "Primal Rend",
                "Cloudsplitter"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            amws = "Primal Rend",
            tpws = L{
            }
        },
        SelfBuffs = L{
            {
                Familiar = "VivaciousVickie",
                ReadyMove = "Zealous Snort",
                Buff = "Counter Boost"
            }
        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Killer Instinct', L{InBattleCondition.new()}),
            JobAbility.new('Spur', L{InBattleCondition.new()}),
        }
    }
}