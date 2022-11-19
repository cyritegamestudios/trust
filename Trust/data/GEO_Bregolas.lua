-- Default trust settings for GEO
TrustSettings = {
    SelfBuffs = S{
    },
    PartyBuffs = S{
        Spell.new('Indi-STR', L{'Entrust'}, L{'DRK','SAM','WAR','MNK'}),
		Spell.new('Indi-DEX', L{'Entrust'}, L{'THF'}),
        Spell.new('Indi-Fury', L{'Entrust'}, L{'RUN'})
    },
    Geomancy = {
        Indi = Spell.new('Indi-Fury', L{}, L{}),
        Geo = Spell.new('Geo-Frailty', L{}, L{}, 'bt')
    }
}
return TrustSettings

