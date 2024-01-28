-- Settings file for MNK
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
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