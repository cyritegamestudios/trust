-- Settings file for RNG
return {
    Version = 2,
    Default = {
        AutoFood = "Grape Daifuku",
        Shooter = {
            Delay = 1.5
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Velocity Shot', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                RangedAttack.new()
            }
        },
    }
}