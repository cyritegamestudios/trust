-- Settings file for DRK
return {
    Version = 1,
    Default = {
        AutoFood="Grape Daifuku",
        SelfBuffs = L{
            Spell.new("Endark II", L{}, L{}, nil, L{IdleCondition.new()}),
            Spell.new("Absorb-STR", L{}, L{}, "bt", L{}),
            Spell.new("Absorb-DEX", L{}, L{}, "bt", L{}),
        },
        PartyBuffs = L{

        },
        JobAbilities = L{
            JobAbility.new('Last Resort', L{InBattleCondition.new()}),
            JobAbility.new('Scarlet Delirium', L{InBattleCondition.new()}),
        },
        Debuffs = L {

        },
        PullSettings = {
            Abilities = L{
                Spell.new('Absorb-STR', L{}, L{}),
                Spell.new('Absorb-DEX', L{}, L{}),
                Spell.new('Stone', L{}, L{})
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Enemy", L{MeleeAccuracyCondition.new(75, "<="), MainJobCondition.new("DRK")},  Spell.new("Absorb-ACC", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasBuffCondition.new("Max HP Boost"), IdleCondition.new(), NotCondition.new(L{HasBuffCondition.new("Dread Spikes")})},  Spell.new("Dread Spikes", L{}, L{}), "Self"),
            },
            Gambits = L{

            }
        },
    }
}
