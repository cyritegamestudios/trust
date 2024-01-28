-- Settings file for RDM
return {
    Version = 2,
    Default = {
        AutoFood = "Grape Daifuku",
        SelfBuffs = L{
            Buff.new("Refresh", L{}, L{}, nil, L{}),
            Buff.new("Haste", L{}, L{}, nil, L{}),
            Buff.new("Temper", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Enblizzard", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Gain-INT", L{}, L{}, nil, L{IdleCondition.new()}),
            Spell.new("Gain-STR", L{}, L{}, nil, L{InBattleCondition.new()}),
            Spell.new("Phalanx", L{}, nil, nil, L{}),
            Buff.new("Protect", L{}, L{}, nil, L{}),
            Buff.new("Shell", L{}, L{}, nil, L{})
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1500,
                Emergency = 35,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 600
            },
            Delay = 2
        },
        JobAbilities = L{
            JobAbility.new('Composure', L{}, L{}, nil),
        },
        PartyBuffs = L{
            Buff.new("Refresh", L{}, L{"DRK", "PUP", "PLD", "BLU", "BLM", "BRD", "GEO", "SMN", "WHM", "RUN"}, nil, L{}),
            Buff.new("Haste", L{}, L{"WAR", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "RUN", "MNK", "THF", "BST", "NIN", "DNC", "DRK", "GEO", "SCH", "BLM"}, nil, L{}),
            Buff.new("Haste", L{}, L{"COR"}, nil, L{InBattleCondition.new()}),
            Buff.new("Flurry", L{}, L{"RNG", "COR"}, nil, L{IdleCondition.new()}),
            Spell.new("Phalanx II", L{}, L{"WAR", "PLD", "BRD", "SAM", "DRG", "BLU", "PUP", "RUN", "MNK", "THF", "BST", "NIN", "DNC", "DRK", "GEO"}, nil, L{InBattleCondition.new()})
        },
        NukeSettings = {
            Delay = 4,
            MinManaPointsPercent = 40,
            MinNumMobsToCleave = 2,
            Spells = L{
                Spell.new('Thunder V'),
                Spell.new('Thunder IV'),
                Spell.new('Thunder III'),
                Spell.new('Blizzard V'),
                Spell.new('Blizzard IV'),
                Spell.new('Blizzard III'),
                Spell.new('Fire V'),
                Spell.new('Fire IV'),
                Spell.new('Fire III'),
                Spell.new('Aero V'),
                Spell.new('Aero IV'),
                Spell.new('Aero III'),
                Spell.new('Water V'),
                Spell.new('Water IV'),
                Spell.new('Water III'),
                Spell.new('Stone V'),
                Spell.new('Stone IV'),
                Spell.new('Stone III'),
            },
            Blacklist = L{

            },
        },
        Debuffs = L{
            Debuff.new("Distract", L{})
        }
    }
}