-- Settings file for BRD
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        SelfBuffs = L{

        },
        SongSettings = {
            NumSongs = 4,
            SongDuration = 240,
            SongDelay = 6,
            Songs = L{
                Spell.new("Honor March", L{"Marcato"}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','WHM'}, nil, L{}),
                Spell.new("Blade Madrigal", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
                Spell.new("Valor Minuet IV", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
                Spell.new("Valor Minuet V", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{}),
                Spell.new("Valor Minuet III", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{})
            },
            PianissimoSongs = L{
                Spell.new("Mage's Ballad III", L{"Pianissimo"}, L{"BLM", "WHM", "GEO", "SCH"}, nil, L{}),
                Spell.new("Sage Etude", L{"Pianissimo"}, L{"BLM"}, nil, L{}),
                Spell.new("Knight's Minne V", L{"Pianissimo"}, L{"PLD","RUN"}, nil, L{}),
            },
            DummySongs = L{
                Spell.new("Scop's Operetta", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{}),
                Spell.new("Goblin Gavotte", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{}),
                Spell.new("Sheepfoe Mambo", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{})
            }
        },
        Debuffs = L{
            Spell.new("Carnage Elegy", L{}, nil, nil, L{})
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Carnage Elegy', L{}, L{})
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        GambitSettings = {
            Gambits = L{

            }
        },
    }
}