-- Default trust settings for GEO
TrustSettings = {
    SelfBuffs = S{
    },
    PartyBuffs = S{
        Spell.new('Indi-STR', L{'Entrust'}, L{'DRK','SAM','WAR','MNK'}),
        Spell.new('Indi-Fury', L{'Entrust'}, L{'RUN'})
    },
    Geomancy = {
        Indi = Spell.new('Indi-Barrier', L{}, L{}),
        Geo = Spell.new('Geo-Fury', L{}, L{}, 'p1')
    }
}
return TrustSettings

