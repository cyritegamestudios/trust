-- Settings file for RNG
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Velocity Shot', L{InBattleCondition.new()}),
        }
    }
}