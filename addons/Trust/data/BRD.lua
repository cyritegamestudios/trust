-- Settings file for BRD
return {
    Version = 1,
    Default = {
        NumSongs = 4,
        SelfBuffs = L{

        },
        SongDuration = 240,
        SongDelay = 6,
        Skillchains = {
            spamws = L{
                "Savage Blade",
                "Mordant Rime"
            },
            starterws = L{
                "Savage Blade",
                "Mordant Rime"
            },
            defaultws = L{
                "Savage Blade",
                "Mordant Rime",
                "Retribution"
            },
            cleavews = L{
                "Aeolian Edge"
            },
            preferws = L{
                "Savage Blade",
                "Mordant Rime",
                "Rudra's Storm"
            },
            amws = "Mordant Rime",
            tpws = L{
                "Mordant Rime"
            }
        },
        PartyBuffs = L{
            Spell.new("Mage's Ballad III", L{"Pianissimo"}, L{"BLM", "WHM", "GEO", "SCH"}, nil, L{}),
            Spell.new("Sage Etude", L{"Pianissimo"}, L{"BLM"}, nil, L{}),
            Spell.new("Knight's Minne V", L{"Pianissimo"}, L{"PLD","RUN"}, nil, L{}),
        },
        DummySongs = L{
            Spell.new("Scop's Operetta", L{}, nil, nil, L{}),
            Spell.new("Goblin Gavotte", L{}, nil, nil, L{}),
            Spell.new("Sheepfoe Mambo", L{}, nil, nil, L{}),
        },
        Debuffs = L{
            Spell.new("Carnage Elegy", L{}, nil, nil, L{})
        },
        Songs = L{
            Spell.new("Honor March", L{"Marcato"}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','WHM'}, nil, L{}),
            Spell.new("Blade Madrigal", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
            Spell.new("Valor Minuet IV", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
            Spell.new("Valor Minuet V", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
            Spell.new("Valor Minuet III", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{})
        }
    }
}