-- Default trust settings for BRD
TrustSettings = {
    SelfBuffs = L{},
    PartyBuffs = L{
        Spell.new("Mage\'s Ballad III", L{'Pianissimo'}, L{'BLM'}),
        Spell.new("Sage Etude", L{'Pianissimo'}, L{'BLM'}),
    },
    Debuffs = L{
        Spell.new('Carnage Elegy')
    },
    Songs = L{
        Spell.new("Honor March", L{'Marcato'}),
        Spell.new("Valor Minuet V", L{}),
        --Spell.new("Dark Carol II", L{}),
        Spell.new("Blade Madrigal", L{}),
        Spell.new("Knight\'s Minne V", L{}),
    },
    DummySongs = L{
        Spell.new("Goddess\'s Hymnus"),
        Spell.new("Army\'s Paeon IV"),
        Spell.new("Scop\'s Operetta"),
        Spell.new("Sheepfoe Mambo")
    },
    NumSongs = 4
}
return TrustSettings

