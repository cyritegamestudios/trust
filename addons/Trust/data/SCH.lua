-- Default trust settings for SCH
TrustSettings = {
    Default = {
        LightArts = {
            SelfBuffs = L{
                Buff.new('Reraise'),
                Buff.new('Protect', L{'Accession'}),
                Buff.new('Shell', L{'Accession'}),
                Buff.new('Regen', L{'Accession', 'Perpetuance'}),
                Spell.new('Phalanx', L{'Accession', 'Perpetuance'}),
                Spell.new('Aurorastorm II', L{})
            },
            PartyBuffs = L{
                --Spell.new('Firestorm II', L {}, L { 'WAR', 'BLU', 'MNK' }),
                Spell.new('Adloquium', L {}, L { 'WAR', 'PUP' })
            }
        },
        DarkArts = {
            SelfBuffs = L{
                Spell.new('Klimaform', L{}),
            },
            PartyBuffs = L{
            }
        },
        CureSettings = {
            Thresholds = {
                ['Default'] = 78,
                ['Emergency'] = 25,
                ['Cure IV'] = 1200,
                ['Cure III'] = 500,
                ['Cure II'] = 0,
            },
            Delay = 2,
            StatusRemovals = {
                Blacklist = L{
                }
            }
        },
        StrategemCooldown = 33,
        Skillchains = {
            defaultws = {'Retribution','Black Halo'},
            tpws = {},
            spamws = {'Black Halo'},
            starterws = {'Black Halo'},
            preferws = {'Retribution','Black Halo'},
            cleavews = {},
            amws = 'Omniscience'
        },
    }
}
return TrustSettings

