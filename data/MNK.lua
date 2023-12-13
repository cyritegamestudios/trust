-- Settings file for MNK
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Victory Smite"
            },
            starterws = L{
                "Tornado Kick"
            },
            defaultws = L{
                "Tornado Kick",
                "Shijin Spiral"
            },
            preferws = L{
                "Shijin Spiral",
                "Victory Smite"
            },
            cleavews = L{
                "Spinning Attack",
                "Cataclysm"
            },
            amws = "Ascetic's Fury",
            tpws = L{
            }
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Impetus', L{InBattleCondition.new()}),
            JobAbility.new('Footwork', L{InBattleCondition.new()}),
            JobAbility.new('Mantra', L{InBattleCondition.new()}),
        }
    }
}