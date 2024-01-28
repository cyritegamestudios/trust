-- Settings file for SMN
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        JobAbilities = L{

        },
        SelfBuffs = L{

        },
        PartyBuffs = L{
            {
                BloodPact = "Hastega II",
                Buff = "Haste",
                Avatar = "Garuda"
            },
            {
                BloodPact = "Crystal Blessing",
                Buff = "TP Bonus",
                Avatar = "Shiva"
            },
            {
                BloodPact = "Ecliptic Howl",
                Buff = "Accuracy Boost",
                Avatar = "Fenrir"
            },
            {
                BloodPact = "Crimson Howl",
                Buff = "Warcry",
                Avatar = "Ifrit"
            }
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
    }
}