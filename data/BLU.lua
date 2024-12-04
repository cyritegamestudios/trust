-- Settings file for BLU
return {
    Version = 2,
    Default = {
        SelfBuffs = L{
            Spell.new("Erratic Flutter", L{}, L{}, nil, L{}),
            Spell.new("Cocoon", L{}, L{}, nil, L{}),
            Spell.new("Barrier Tusk", L{}, L{}, nil, L{}),
            Spell.new("Nat. Meditation", L{}, L{}, nil, L{}),
            Spell.new("Occultation", L{}, L{}, nil, L{}),
            Spell.new("Mighty Guard", L{"Diffusion", "Unbridled Learning"}, L{}, nil, L{}),
        },
        PartyBuffs = L{

        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 600,
                Emergency = 40,
                Default = 65,
                ["Cure III"] = 400,
                ["Curaga III"] = 800,
                ["Cure II"] = 0,
                ["Curaga II"] = 400,
                Curaga = 0
            },
            MinNumAOETargets = 3,
            Delay = 2,
            StatusRemovals = {
                Delay = 3,
                Blacklist = L{

                }
            }
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Glutinous Dart', L{}, L{}),
                Approach.new(),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        BlueMagicSettings = {
            SpellSets = {
                Default = BlueMagicSet.new(L{"White Wind", "Molting Plumage", "Thrashing Assault", "Fantod", "Erratic Flutter", "Tail Slap", "Paralyzing Triad", "Metallic Body", "Diffusion Ray", "Magic Fruit", "Embalming Earth", "Sudden Lunge", "Sinker Drill", "Cocoon", "Occultation", "Heavy Strike", "Nat. Meditation", "Empty Thrash", "Sickle Slash"})
            }
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BLU")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}