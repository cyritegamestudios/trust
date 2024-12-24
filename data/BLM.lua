-- Settings file for BLM
return {
    Version = 2,
    Default = {
        SelfBuffs = L{
            JobAbility.new('Mana Wall', L{}, L{}, nil),
        },
        PartyBuffs = L{

        },
        Debuffs = L{
            Spell.new("Burn", L{}, nil, nil, L{})
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
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
            JobAbilities = L{
                JobAbility.new("Ebullience", L{SubJobCondition.new('SCH'), StrategemCountCondition.new(1, ">=")}, L{}),
                JobAbility.new("Manawell", L{}, L{}),
                JobAbility.new("Cascade", L{MinManaPointsPercentCondition.new(40), MinTacticalPointsCondition.new(1000)}, L{})
            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Abilities = L{
                Spell.new('Burn', L{}, L{})
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        TargetSettings = {
            Retry = true
        },
        GambitSettings = {
            Default = L{
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("BLM")}, UseItem.new("Tropical Crepe", L{ItemCountCondition.new("Tropical Crepe", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}