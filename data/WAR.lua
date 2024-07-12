-- Settings file for WAR
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Berserk', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Aggressor', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Warcry', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Restraint', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Blood Rage', L{InBattleCondition.new()}, L{}, nil),
            JobAbility.new('Retaliation', L{}, L{}, nil),
        },
        PullSettings = {
            Abilities = L{
                JobAbility.new('Provoke', L{}, L{})
            },
            Distance = 20
        },
    }
}