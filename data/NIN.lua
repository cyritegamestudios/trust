-- Settings file for NIN
return {
    Version = 2,
    Default = {
        AutoFoodMode="Grape Daifuku",
        SelfBuffs = L{
            Spell.new("Utsusemi: San", L{}, L{}, nil, L{}),
            Spell.new("Utsusemi: Ni", L{}, L{}, nil, L{}),
            Spell.new("Utsusemi: Ichi", L{}, L{}, nil, L{}),
        },
        PartyBuffs = L{

        },
        Debuffs = L{

        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 0,
            MinNumMobsToCleave = 2,
            Spells = L{
                Spell.new('Raiton: San'),
                Spell.new('Raiton: Ni'),
                Spell.new('Hyoton: San'),
                Spell.new('Hyoton: Ni'),
                Spell.new('Katon: San'),
                Spell.new('Katon: Ni'),
                Spell.new('Huton: San'),
                Spell.new('Huton: Ni'),
                Spell.new('Suiton: San'),
                Spell.new('Suiton: Ni'),
                Spell.new('Doton: San'),
                Spell.new('Doton: Ni'),
            },
            Blacklist = L{

            },
        },
        JobAbilities = L{
            JobAbility.new('Yonin', L{InBattleCondition.new()}),
        },
        PullSettings = {
            Abilities = L{
                Spell.new("Jubaku: Ni", L{}, L{})
            },
            Distance = 20
        },
    }
}