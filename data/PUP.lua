-- Settings file for PUP
return {
    Version = 2,
    Default = {
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 1.5,
        },
        BuffSettings = {
            Gambits = L{
            }
        },
        DebuffSettings = {
            Gambits = L{
            }
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
        AutomatonSettings = {
            ManeuverSettings = {
                Default = {
                    Tank = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    LightTank = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    Melee = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    Ranged = ManeuverSet.new(2, 0, 0, 1, 0, 0, 0, 0),
                    HybridRanged = ManeuverSet.new(1, 0, 0, 1, 0, 0, 1, 0),
                    Magic = ManeuverSet.new(0, 0, 0, 0, 2, 0, 0, 1),
                    Nuke = ManeuverSet.new(0, 0, 0, 0, 3, 0, 0, 0),
                    Heal = ManeuverSet.new(0, 0, 0, 0, 0, 0, 2, 1),
                },
                Overdrive = {
                    Tank = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    LightTank = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    Melee = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                    Ranged = ManeuverSet.new(2, 0, 0, 1, 0, 0, 0, 0),
                    HybridRanged = ManeuverSet.new(1, 0, 0, 0, 0, 1, 1, 0),
                    Magic = ManeuverSet.new(0, 0, 0, 0, 2, 0, 0, 1),
                    Nuke = ManeuverSet.new(0, 0, 0, 0, 3, 0, 0, 0),
                    Heal = ManeuverSet.new(0, 0, 0, 0, 0, 0, 2, 1),
                },
                Custom = {
                    Default = ManeuverSet.new(1, 0, 1, 0, 0, 0, 1, 0),
                }
            },
            AttachmentSettings = {
                Default = {
                    Tank = AttachmentSet.new("Valoredge Frame", "Soulsoother Head", L{"Strobe", "Strobe II", "Heat Capacitor II", "Mana Jammer IV", "Mana Jammer III", "Regulator", "Armor Plate IV", "Barrier Module II", "Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Flashbulb"}),
                    LightTank = AttachmentSet.new("Valoredge Frame", "Soulsoother Head", L{"Strobe", "Strobe II", "Magniplug", "Magniplug II", "Coiler II", "Armor Plate IV", "Turbo Charger", "Turbo Charger II", "Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Flashbulb"}),
                    Melee = AttachmentSet.new("Sharpshot Frame", "Valoredge Head", L{"Inhibitor", "Inhibitor II", "Attuner", "Magniplug", "Magniplug II", "Speedloader II", "Truesights", "Turbo Charger", "Turbo Charger II", "Optic Fiber", "Optic Fiber II", "Coiler II"}),
                    Ranged = AttachmentSet.new("Sharpshot Frame", "Sharpshot Head", L{"Inhibitor", "Inhibitor II", "Magniplug", "Magniplug II", "Attuner", "Truesights", "Barrage Turbine", "Repeater", "Drum Magazine", "Scope IV", "Optic Fiber", "Optic Fiber II"}),
                    HybridRanged = AttachmentSet.new("Sharpshot Frame", "Valoredge Head", L{"Inhibitor", "Inhibitor II", "Attuner", "Magniplug", "Magniplug II", "Speedloader II", "Truesights", "Turbo Charger", "Turbo Charger II", "Optic Fiber", "Optic Fiber II", "Coiler II"}),
                    Magic = AttachmentSet.new("Stormwaker Frame", "Spiritreaver Head", L{"Loudspeaker IV", "Ice Maker", "Amplifier", "Amplifier II", "Arcanoclutch", "Optic Fiber", "Optic Fiber II", "Arcanic Cell", "Arcanic Cell II", "Mana Tank III", "Mana Tank IV", "Mana Conserver"}),
                    Nuke = AttachmentSet.new("Stormwaker Frame", "Spiritreaver Head", L{"Loudspeaker IV", "Ice Maker", "Amplifier", "Amplifier II", "Arcanoclutch", "Optic Fiber", "Optic Fiber II", "Arcanic Cell", "Arcanic Cell II", "Mana Tank III", "Mana Tank IV", "Mana Conserver"}),
                    Heal = AttachmentSet.new("Stormwaker Frame", "Soulsoother Head", L{"Mana Booster", "Tactical Processor", "Mana Tank II", "Mana Tank IV", "Damage Gauge", "Damage Gauge II", "Optic Fiber", "Optic Fiber II", "Vivi-Valve II", "Resister", "Resister II", "Scanner"}),
                },
                Overdrive = {
                    HybridRanged = AttachmentSet.new("Sharpshot Frame", "Valoredge Head", L{"Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Coiler II", "Inhibitor", "Inhibitor II", "Magniplug", "Magniplug II", "Attuner", "Speedloader II", "Turbo Charger II", "Truesights"}),
                },
                Custom = {
                    Default = AttachmentSet.new("Valoredge Frame", "Soulsoother Head", L{"Strobe", "Strobe II", "Magniplug", "Magniplug II", "Coiler II", "Armor Plate IV", "Turbo Charger", "Turbo Charger II", "Auto-Repair Kit IV", "Optic Fiber", "Optic Fiber II", "Flashbulb"})
                }
            },
        },
        GambitSettings = {
            Default = L{
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasPetCondition.new(L{})}), "Self"), GambitCondition.new(ModeCondition.new("AutoPetMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{InTownCondition.new()}), "Self")}, JobAbility.new("Activate", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasPetCondition.new(L{})}), "Self"), GambitCondition.new(ModeCondition.new("AutoPetMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{InTownCondition.new()}), "Self")}, JobAbility.new("Deus Ex Automata", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasPetCondition.new(L{}), "Self"), GambitCondition.new(PetHitPointsPercentCondition.new(20, "<="), "Self"), GambitCondition.new(ModeCondition.new("AutoRepairMode", "Auto"), "Self")}, JobAbility.new("Repair", L{}, L{}), "Self"),
                Gambit.new("Self", L{GambitCondition.new(HasBuffCondition.new("Overload"), "Self")}, JobAbility.new("Cooldown", L{}, L{}), "Self"),
            },
            Gambits = L{
                Gambit.new("Self", L{GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(MainJobCondition.new("PUP"), "Self")}, UseItem.new("Grape Daifuku", L{ItemCountCondition.new("Grape Daifuku", 1, ">=")}), "Self", L{"food"}),
            }
        },
        ReactionSettings = {
            Gambits = L{
            }
        },
        GearSwapSettings = {
            Enabled = true,
            Language = "en"
        },
    }
}