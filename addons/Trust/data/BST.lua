-- Settings file for BST
return {
    Version = 1,
    Default = {
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

            },
            amws = "Primal Rend",
            tpws = L{
                "Decimation",
                "Cloudsplitter"
            }
        },
        SelfBuffs = L{
            {
                Familiar = "VivaciousVickie",
                ReadyMove = "Zealous Snort",
                Buff = "Counter Boost"
            }
        },
        JobAbilities = L{
            JobAbility.new('Killer Instinct', L{InBattleCondition.new()}),
            JobAbility.new('Spur', L{InBattleCondition.new()}),
        }
    }
}