-- Settings file for BRD
return {
    Version = 1,
    Default = {
        SongSettings = {
            NumSongs = 4,
            SongDuration = 240,
            SongDelay = 6,
            SongSets = {
                Default = {
                    Songs = L{
                        Spell.new("Honor March", L{"Marcato"}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','WHM','RDM'}, nil, L{}),
                        Spell.new("Blade Madrigal", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','RDM'}, nil, L{}),
                        Spell.new("Valor Minuet IV", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','RDM'}, nil, L{}),
                        Spell.new("Valor Minuet V", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR','RDM'}, nil, L{}),
                        Spell.new("Valor Minuet III", L{}, L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','COR'}, nil, L{})
                    },
                    PianissimoSongs = L{
                        Spell.new("Mage's Ballad III", L{"Pianissimo"}, L{"BLM", "WHM", "GEO", "SCH", "RDM"}, nil, L{}),
                        Spell.new("Sage Etude", L{"Pianissimo"}, L{"BLM"}, nil, L{}),
                        Spell.new("Knight's Minne V", L{"Pianissimo"}, L{"PLD","RUN"}, nil, L{}),
                    },
                },
            },
            DummySongs = L{
                Spell.new("Scop's Operetta", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{}),
                Spell.new("Goblin Gavotte", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{}),
                Spell.new("Sheepfoe Mambo", L{}, L{"WAR", "WHM", "RDM", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "SCH", "RUN", "MNK", "BLM", "THF", "BST", "RNG", "NIN", "SMN", "COR", "DNC", "GEO", "DRK"}, nil, L{})
            }
        },
        DebuffSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Debuff.new("Carnage Elegy", L{}, L{}, L{}), "Enemy", L{"Debuffs"})
            }
        },
        BuffSettings = {
            Gambits = L{

            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Spell.new("Carnage Elegy", L{}, L{}, nil, L{}, nil, true), "Enemy", L{"Pulling"}),
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20,
            MaxNumTargets = 1,
        },
        TargetSettings = {
            Retry = false
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BRD")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"Food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}