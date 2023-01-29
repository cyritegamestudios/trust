-- Default trust settings for BLU
TrustSettings = {
    Default = {
        SelfBuffs = S{
            Spell.new('Erratic Flutter', L{}),
            Spell.new('Cocoon', L{}),
            Spell.new('Barrier Tusk', L{}),
            Spell.new('Nat. Meditation', L{}),
            Spell.new('Occultation', L{}),
            Spell.new('Mighty Guard', L{'Unbridled Learning'})
        },
        Skillchains = {
            defaultws = {'Expiacion','Savage Blade'},
            tpws = {'Expiacion','Savage Blade'},
            spamws = {'Savage Blade','Black Halo'},
            starterws = {'Savage Blade'},
            preferws = {'Expiacion','Savage Blade'},
            cleavews = {},
            amws = 'Expiacion'
        }
    }
}
return TrustSettings

