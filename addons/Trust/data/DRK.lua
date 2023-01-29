-- Default trust settings for DRK
TrustSettings = {
    Default = {
        SelfBuffs = S{
            Spell.new('Endark II', L {}),
            Spell.new('Absorb-DEX', L {}, L {}, 'bt'),
            Spell.new('Absorb-STR', L {}, L {}, 'bt')
        },
        JobAbilities = S{
            'Last Resort',
            'Scarlet Delirium'
        },
        Skillchains = {
            defaultws = {'Cross Reaper','Catastrophe','Insurgency','Entropy','Torcleaver'},
            tpws = {'Cross Reaper'},
            spamws = {'Catastrophe','Torcleaver','Cross Reaper','Entropy','Judgment','Savage Blade'},
            starterws = {'Torcleaver','Catastrophe','Cross Reaper','Entropy'},
            preferws = {'Cross Reaper','Catastrophe','Torcleaver'},
            cleavews = {'Fell Cleave'},
            amws = 'Entropy'
        }
    }
}
return TrustSettings

