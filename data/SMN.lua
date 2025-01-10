-- Settings file for SMN
return {
    Version = 2,
    Default = {
        BuffSettings = {
            Gambits = L{
                Gambit.new("Self", L{}, BloodPactWard.new("Reraise II", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, BloodPactWard.new("Crimson Howl", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, BloodPactWard.new("Hastega II", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, BloodPactWard.new("Crystal Blessing", L{}), "Self", L{"Buffs"}),
                Gambit.new("Self", L{}, BloodPactWard.new("Ecliptic Howl", L{}), "Self", L{"Buffs"}),
            }
        },
        NukeSettings = {
            Delay = 2,
            MinManaPointsPercent = 20,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Gambits = L{
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Meteorite'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Holy Mist'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Impact'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Geocrush'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Grand Fall'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Wind Blade'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Thunderstorm'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Meteor Strike'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Heavenly Strike'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Nether Blast'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Night Terror'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Level ? Holy'), "Enemy", L{}),
                Gambit.new("Enemy", L{}, BloodPactMagic.new('Tornado II'), "Enemy", L{}),
            },
            JobAbilities = L{

            },
            Blacklist = L{

            },
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Gambits = L{
                Gambit.new("Enemy", L{}, Approach.new(), "Enemy", L{"Pulling"}),
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20,
            MaxNumTargets = 1,
        },
        TargetSettings = {
            Retry = false
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Avatar's Favor")}), HasPetCondition.new(L{'Carbuncle', 'Cait Sith', 'Ifrit', 'Shiva', 'Garuda', 'Titan', 'Ramuh', 'Leviathan', 'Fenrir', 'Diabolos', 'Siren'})}, JobAbility.new("Avatar's Favor", L{}), "Self", L{})
            },
            Gambits = L{
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("SMN")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}