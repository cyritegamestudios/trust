-- Settings file for NIN
return {
    Version = 1,
    Default = {
        AutoFoodMode="Grape Daifuku",
        Skillchains = {
            spamws = L{
                "Blade: Ku",
                "Tachi: Gekko",
                "Asuran Fists"
            },
            starterws = L{
                "Blade: Kamu",
                "Tachi: Ageha"
            },
            defaultws = L{
                "Blade: Hi",
                "Blade: Shun",
                "Tachi: Ageha",
                "Evisceration",
                "Asuran Fists"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            preferws = L{
                "Blade: Ku",
                "Evisceration",
                "Blade: To",
                "Blade: Chi",
                "Blade: Teki"
            },
            amws = "Blade: Kamu",
            tpws = L{
            }
        },
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