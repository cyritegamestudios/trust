-- Settings file for NIN
return {
    Version = 1,
    Default = {
        AutoFoodMode="Grape Daifuku",
        SelfBuffs = L{
            Spell.new("Utsusemi: Ni", L{}, L{}, nil, L{})
        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Yonin', L{InBattleCondition.new()}),
        }
    }
}