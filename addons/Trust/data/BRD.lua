-- Default trust settings for BRD
TrustSettings = {
    Default = {
        SelfBuffs = L{},
        PartyBuffs = L{
            Spell.new("Mage's Ballad III", L{'Pianissimo'}, L{'BLM','WHM','GEO','SCH'}),
            Spell.new("Sage Etude", L{'Pianissimo'}, L{'BLM'}),
        },
        Debuffs = L{
            Spell.new('Carnage Elegy')
        },
        Songs = L{
            Spell.new("Honor March", L{'Marcato'}),
            Spell.new("Valor Minuet V", L{}),
            Spell.new("Valor Minuet IV", L{}),
            Spell.new("Blade Madrigal", L{}),
            Spell.new("Valor Minuet III", L{}),
        },
        DummySongs = L{
            Spell.new("Goddess's Hymnus"),
            Spell.new("Army's Paeon IV"),
            Spell.new("Scop's Operetta"),
            Spell.new("Sheepfoe Mambo"),
            Spell.new("Goblin Gavotte")
        },
        NumSongs = 4,
        SongDuration = 240,
        Skillchains = {
            defaultws = {'Savage Blade','Mordant Rime','Retribution'},
            tpws = {'Mordant Rime'},
            spamws = {'Savage Blade','Mordant Rime'},
            cleavews = {'Aeolian Edge'},
            starterws = {'Savage Blade','Mordant Rime'},
            preferws = {'Savage Blade','Mordant Rime',"Rudra's Storm"},
            amws = 'Mordant Rime'
        }
    }
}
return TrustSettings

