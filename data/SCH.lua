-- Default trust settings for SCH
TrustSettings = {
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
            ['Cure IV'] = 1200,
            ['Cure III'] = 500,
            ['Cure II'] = 0,
        }
    }
}
return TrustSettings

