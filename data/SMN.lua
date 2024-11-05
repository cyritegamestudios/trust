-- Settings file for SMN
return {
    Version = 2,
    Default = {
        JobAbilities = L{
        },
        SelfBuffs = L{

        },
        PartyBuffs = L{
            JobAbility.new("Reraise II", L{}),
            JobAbility.new("Crimson Howl", L{}),
            JobAbility.new("Hastega II", L{}),
            JobAbility.new("Crystal Blessing", L{}),
            JobAbility.new("Ecliptic Howl", L{}),
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Spells = L{
                BloodPactMagic.new('Meteorite'),
                BloodPactMagic.new('Holy Mist'),
                BloodPactMagic.new('Impact'),
                BloodPactMagic.new('Geocrush'),
                BloodPactMagic.new('Grand Fall'),
                BloodPactMagic.new('Wind Blade'),
                BloodPactMagic.new('Thunderstorm'),
                BloodPactMagic.new('Meteor Strike'),
                BloodPactMagic.new('Heavenly Strike'),
                BloodPactMagic.new('Nether Blast'),
                BloodPactMagic.new('Night Terror'),
                BloodPactMagic.new('Level ? Holy'),
                BloodPactMagic.new('Tornado II'),
            },
            JobAbilities = L{

            },
            Blacklist = L{

            },
        },
        PullSettings = {
            Abilities = L{
                Approach.new()
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
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("SMN")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
    }
}