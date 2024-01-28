-- Settings file for DRK
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        SelfBuffs = L{
            Spell.new("Endark II", L{}, L{}, nil, L{}),
            Spell.new("Absorb-DEX", L{}, L{}, "bt", L{}),
            Spell.new("Absorb-STR", L{}, L{}, "bt", L{}),
            Spell.new("Dread Spikes", L{}, L{}, nil, L{HasBuffCondition.new("Max HP Boost"), IdleCondition.new()})
        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Last Resort', L{InBattleCondition.new()}),
            JobAbility.new('Scarlet Delirium', L{InBattleCondition.new()}),
        },
        Debuffs = L {

        }
    }
}
