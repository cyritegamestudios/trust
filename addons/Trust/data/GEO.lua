-- Default trust settings for GEO
TrustSettings = {
    Default = {
        JobAbilities = L{
        },
        SelfBuffs = L{
        },
        PartyBuffs = L{
            Spell.new('Indi-STR', L{'Entrust'}, L{'DRK','SAM','WAR','MNK'}),
            Spell.new('Indi-Fury', L{'Entrust'}, L{'RUN'})
        },
        Geomancy = {
            Indi = Spell.new('Indi-Acumen', L{}, L{}),
            Geo = Spell.new('Geo-Malaise', L{}, L{}, 'bt')
        },
        Skillchains = {
            defaultws = {'Black Halo'},
            tpws = {'Black Halo'},
            spamws = {'Black Halo'},
            starterws = {},
            preferws = {'Black Halo'},
            cleavews = {},
            amws = 'Exudation'
        }
    }
}
return TrustSettings

