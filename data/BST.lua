-- Settings file for BST
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
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
        },
        PullSettings = {
            Abilities = L{
            }
        },
    }
}