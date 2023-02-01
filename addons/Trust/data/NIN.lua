-- Default trust settings for NIN
TrustSettings = {
    Default = {
        JobAbilities = L{
        },
        SelfBuffs = L{
            --Spell.new('Utsusemi: Ni', L{}, L{}, nil),
        },
        Skillchains = {
            defaultws = {'Blade: Hi','Blade: Shun','Tachi: Ageha','Evisceration','Asuran Fists'},
            tpws = {'Blade: Shun','Evisceration'},
            spamws = {'Blade: Ku','Tachi: Gekko','Asuran Fists'},
            cleavews = {},
            starterws = {'Blade: Kamu','Tachi: Ageha'},
            preferws = {'Blade: Ku','Evisceration','Blade: To','Blade: Chi','Blade: Teki'},
            amws = 'Blade: Kamu'
        },
    }
}
return TrustSettings

