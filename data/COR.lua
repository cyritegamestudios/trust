-- Settings file for COR
return {
    Version = 2,
    Default = {
        AutoFood="Grape Daifuku",
        Shooter = {
            Delay = 1.5
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        Roll1 = Roll.new("Chaos Roll", true),
        Roll2 = Roll.new("Samurai Roll", false),
        PullSettings = {
            Abilities = L{
                RangedAttack.new()
            },
            Distance = 20
        },
    }
}