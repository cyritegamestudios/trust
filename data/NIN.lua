-- Settings file for NIN
return {
    Version = 2,
    Default = {
        SelfBuffs = L{
            Spell.new("Utsusemi: San", L{}, L{}, nil, L{}),
            Spell.new("Utsusemi: Ni", L{}, L{}, nil, L{}),
            Spell.new("Utsusemi: Ichi", L{}, L{}, nil, L{}),
            Spell.new("Kakka: Ichi", L{}, L{}, nil, L{}),
            Spell.new("Myoshu: Ichi", L{}, L{}, nil, L{}),
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
            JobAbilities = L{
                JobAbility.new("Futae", L{}, L{}),
            },
            Blacklist = L{

            },
        },
        JobAbilities = L{
            JobAbility.new('Yonin', L{InBattleCondition.new()}),
            JobAbility.new('Issekigan', L{InBattleCondition.new()}, L{}, nil),
        },
        PullSettings = {
            Abilities = L{
                Spell.new("Jubaku: Ni", L{}, L{}),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("NIN")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}