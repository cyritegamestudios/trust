-- Settings file for BLU
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        JobAbilities = L{

        },
        SelfBuffs = L{
            Spell.new("Erratic Flutter", L{}, L{}, nil, L{SpellRecastReadyCondition.new(710)}),
            Spell.new("Cocoon", L{}, L{}, nil, L{SpellRecastReadyCondition.new(547)}),
            Spell.new("Barrier Tusk", L{}, L{}, nil, L{SpellRecastReadyCondition.new(685)}),
            Spell.new("Nat. Meditation", L{}, L{}, nil, L{SpellRecastReadyCondition.new(700)}),
            Spell.new("Occultation", L{}, L{}, nil, L{SpellRecastReadyCondition.new(679)}),
            Spell.new("Mighty Guard", L{"Unbridled Learning"}, L{}, nil, L{SpellRecastReadyCondition.new(750)}),
        },
        PartyBuffs = L{

        },
    }
}