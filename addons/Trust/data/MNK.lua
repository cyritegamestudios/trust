-- Settings file for MNK
return {
    Version = 1,
    Default = {
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

            },
            amws = "Ascetic's Fury",
            tpws = L{
                "Howling Fist"
            }
        },
        JobAbilities = L{
            JobAbility.new('Impetus', L{InBattleCondition.new()}),
            JobAbility.new('Footwork', L{InBattleCondition.new()}),
            JobAbility.new('Mantra', L{InBattleCondition.new()}),
        }
    }
}