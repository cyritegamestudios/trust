-- Settings file for SMN
return {
    Version = 2,
    Default = {
        AutoFood = "Grape Daifuku",
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
            Blacklist = L{

            },
        },
        PullSettings = {
            Abilities = L{
            },
            Distance = 20
        },
        GambitSettings = {
            Gambits = L{

            }
        },
    }
}