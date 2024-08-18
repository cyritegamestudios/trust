-- Settings file for BLM
return {
    Version = 2,
    Default = {
        AutoFood="Tropical Crepe",
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        Debuffs = L{
            Spell.new("Burn", L{}, nil, nil, L{})
        },
        JobAbilities = L{
            JobAbility.new('Mana Wall', L{}, L{}, nil),
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            Spells = L{
                Spell.new('Thunder VI'),
                Spell.new('Thunder V'),
                Spell.new('Thundaja'),
                Spell.new('Thunder IV'),
                Spell.new('Blizzard VI'),
                Spell.new('Blizzard V'),
                Spell.new('Blizzaja'),
                Spell.new('Blizzard IV'),
                Spell.new('Fire VI'),
                Spell.new('Fire V'),
                Spell.new('Firaja'),
                Spell.new('Fire IV'),
                Spell.new('Aero VI'),
                Spell.new('Aero V'),
                Spell.new('Aeroja'),
                Spell.new('Aero IV'),
                Spell.new('Water VI'),
                Spell.new('Water V'),
                Spell.new('Waterja'),
                Spell.new('Water IV'),
                Spell.new('Stone VI'),
                Spell.new('Stone V'),
                Spell.new('Stoneja'),
                Spell.new('Stone IV'),
                Spell.new('Comet'),
            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Burn', L{}, L{})
            },
            Distance = 20
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{MinManaPointsPercentCondition.new(50), InBattleCondition.new()}, JobAbility.new("Cascade", L{}, L{}), "Self", L{})
            },
            Gambits = L{

            }
        },
    }
}