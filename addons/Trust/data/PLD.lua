-- Default trust settings for PLD
TrustSettings = {
    Default = {
        JobAbilities = S{
            'Majesty'
        },
        SelfBuffs = S{
            Spell.new('Phalanx', L{}),
            Spell.new('Protect V', L{}),
        },
        PartyBuffs = S{
        },
        CureSettings = {
            Thresholds = {
                ['Default'] = 78,
                ['Emergency'] = 25,
                ['Cure IV'] = 1000,
                ['Cure III'] = 400,
                ['Cure II'] = 0,
            },
            Delay = 2,
            StatusRemovals = {
                Blacklist = L{
                }
            }
        },
        Skillchains = {
            defaultws = {'Savage Blade','Torcleaver'},
            tpws = {},
            spamws = {'Savage Blade','Torcleaver'},
            starterws = {'Red Lotus Blade'},
            preferws = {'Red Lotus Blade','Torcleaver'},
            cleavews = {'Circle Blade'},
            amws = 'Torcleaver'
        }
    }
}
return TrustSettings

