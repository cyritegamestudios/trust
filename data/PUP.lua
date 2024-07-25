-- Settings file for PUP
return {
    Version = 1,
    Default = {
        AutoFood = "Grape Daifuku",
        JobAbilities = L{},
        SelfBuffs = L{

        },
        PartyBuffs = L{

        },
        PullSettings = {
            Abilities = L{
            },
            Distance = 20
        },
        AttachmentSettings = {
            Sets = {
                Tank = AttachmentSet.new("Valoredge Frame", "Soulsoother Head", L{"Strobe", "Strobe II", "Heat Capacitor II", "Mana Jammer IV", "Mana Jammer III", "Regulator", "Armor Plate IV", "Barrier Module II", "Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Flashbulb"}),
                Melee = AttachmentSet.new("Sharpshot Frame", "Valoredge Head", L{"Inhibitor", "Inhibitor II", "Attuner", "Magniplug", "Magniplug II", "Speedloader II", "Truesights", "Turbo Charger", "Turbo Charger II", "Optic Fiber", "Optic Fiber II", "Coiler II"}),
                Healer = AttachmentSet.new("Stormwaker Frame", "Soulsoother Head", L{"Mana Booster", "Tactical Processor", "Mana Tank II", "Mana Tank IV", "Damage Gauge", "Damage Gauge II", "Optic Fiber", "Optic Fiber II", "Vivi-Valve II", "Resister", "Resister II", "Scanner"}),
                Ranger = AttachmentSet.new("Sharpshot Frame", "Sharpshot Head", L{"Inhibitor", "Inhibitor II", "Magniplug", "Magniplug II", "Attuner", "Truesights", "Barrage Turbine", "Repeater", "Drum Magazine", "Scope IV", "Optic Fiber", "Optic Fiber II"}),
                OverdriveRanger = AttachmentSet.new("Sharpshot Frame", "Valoredge Head", L{"Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Coiler II", "Inhibitor", "Inhibitor II", "Magniplug", "Magniplug II", "Attuner", "Speedloader II", "Turbo Charger II", "Truesights"}),
                Nuker = AttachmentSet.new("Stormwaker Frame", "Spiritreaver Head", L{"Loudspeaker IV", "Ice Maker", "Amplifier", "Amplifier II", "Arcanoclutch", "Optic Fiber", "Optic Fiber II", "Arcanic Cell", "Arcanic Cell II", "Mana Tank III", "Mana Tank IV", "Mana Conserver"})
            }
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{NotCondition.new(L{HasPetCondition.new(L{})}), ModeCondition.new("AutoPetMode", "Auto")}, JobAbility.new("Activate", L{}, L{}), "Self"),
                Gambit.new("Self", L{NotCondition.new(L{HasPetCondition.new(L{})}), ModeCondition.new("AutoPetMode", "Auto")}, JobAbility.new("Deus Ex Automata", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasPetCondition.new(L{}), PetHitPointsPercentCondition.new(20, "<="), ModeCondition.new("AutoRepairMode", "Auto")}, JobAbility.new("Repair", L{}, L{}), "Self"),
                Gambit.new("Self", L{HasBuffCondition.new("Overload")}, JobAbility.new("Cooldown", L{}, L{}), "Self"),
            },
            Gambits = L{

            }
        },
        DefaultManeuvers = {
            Ranged = L{
                {
                    Name = "Wind Maneuver",
                    Amount = 1
                },
                {
                    Name = "Fire Maneuver",
                    Amount = 2
                },
                {
                    Name = "Light Maneuver",
                    Amount = 0
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                }
            },
            HybridRanged = L{
                {
                    Name = "Wind Maneuver",
                    Amount = 0
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Fire Maneuver",
                    Amount = 2
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                }
            },
            Melee = L{
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                },
                {
                    Name = "Wind Maneuveras",
                    Amount = 0
                },
                {
                    Name = "Water Maneuver",
                    Amount = 1
                },
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                }
            },
            LightTank = L{
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                },
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Dark Maneuver",
                    Amount = 0
                },
                {
                    Name = "Water Maneuver",
                    Amount = 1
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                }
            },
            Tank = L{
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                },
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Dark Maneuver",
                    Amount = 0
                },
                {
                    Name = "Water Maneuver",
                    Amount = 1
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                }
            },
            Heal = L{
                {
                    Name = "Light Maneuver",
                    Amount = 2
                },
                {
                    Name = "Dark Maneuver",
                    Amount = 1
                },
                {
                    Name = "Water Maneuver",
                    Amount = 0
                },
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                }
            },
            Magic = L{
                {
                    Name = "Light Maneuver",
                    Amount = 0
                },
                {
                    Name = "Ice Maneuver",
                    Amount = 2
                },
                {
                    Name = "Dark Maneuver",
                    Amount = 1
                },
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                }
            },
            Nuke = L{
                {
                    Name = "Ice Maneuver",
                    Amount = 3
                },
                {
                    Name = "Dark Maneuver",
                    Amount = 0
                },
                {
                    Name = "Water Maneuver",
                    Amount = 0
                },
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                }
            }
        },
        OverdriveManeuvers = {
            HybridRanged = L{
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 1
                },
                {
                    Name = "Wind Maneuver",
                    Amount = 0
                }
            },
            Melee = L{
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Thunder Maneuver",
                    Amount = 0
                },
                {
                    Name = "Water Maneuver",
                    Amount = 1
                },
                {
                    Name = "Earth Maneuver",
                    Amount = 0
                }
            },
            LightTank = L{
                {
                    Name = "Fire Maneuver",
                    Amount = 1
                },
                {
                    Name = "Light Maneuver",
                    Amount = 1
                },
                {
                    Name = "Water Maneuver",
                    Amount = 1
                }
            }
        }
    }
}