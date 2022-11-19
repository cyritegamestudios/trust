-- Default trust settings for PUP
TrustSettings = {
    AutomatonName = 'Pamama',
    DefaultManeuvers = {
        Melee = L{
            {Name='Fire Maneuver', 	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Thunder Maneuver', Amount=0},
            {Name='Wind Maneuveras',  Amount=0},
            {Name='Water Maneuver',	  Amount=1},
            {Name='Earth Maneuver',	  Amount=0},
        },

        Ranged = L{
            {Name='Wind Maneuver', 	  Amount=1},
            {Name='Fire Maneuver',	  Amount=2},
            {Name='Light Maneuver',	  Amount=0},
            {Name='Thunder Maneuver', Amount=0},
        },
        HybridRanged = L{
            {Name='Wind Maneuver', 	  Amount=0},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Fire Maneuver',	  Amount=2},
            {Name='Thunder Maneuver', Amount=0},
        },
        Tank = L{
            {Name='Earth Maneuver',	  Amount=0},
            {Name='Fire Maneuver',	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Dark Maneuver',	  Amount=0},
            {Name='Water Maneuver',	  Amount=1},
            {Name='Thunder Maneuver', Amount=0},
        },
        LightTank = L{
            {Name='Earth Maneuver',	  Amount=0},
            {Name='Fire Maneuver',	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Dark Maneuver',	  Amount=0},
            {Name='Water Maneuver',   Amount=1},
            {Name='Thunder Maneuver', Amount=0},
        },
        Magic = L{
            {Name='Light Maneuver',	  Amount=0},
            {Name='Ice Maneuver',	  Amount=2},
            {Name='Dark Maneuver',	  Amount=1},
            {Name='Earth Maneuver',	  Amount=0},
        },
        Heal = L{
            {Name='Light Maneuver',	  Amount=2},
            {Name='Dark Maneuver',	  Amount=1},
            {Name='Water Maneuver',	  Amount=0},
            {Name='Earth Maneuver',	  Amount=0},
        },
        Nuke = L{
            {Name='Ice Maneuver',	  Amount=3},
            {Name='Dark Maneuver',	  Amount=0},
            {Name='Water Maneuver',	  Amount=0},
            {Name='Earth Maneuver',	  Amount=0},
        },
    },
    OverdriveManeuvers = {
        Melee = L{
            {Name='Fire Maneuver',	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Thunder Maneuver', Amount=0},
            {Name='Water Maneuver', Amount=1},
            {Name='Earth Maneuver', Amount=0},
        },
        HybridRanged = L{
            {Name='Fire Maneuver',	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Thunder Maneuver', Amount=1},
            {Name='Wind Maneuver', Amount=0},
        },
        LightTank = L{
            {Name='Fire Maneuver',	  Amount=1},
            {Name='Light Maneuver',	  Amount=1},
            {Name='Water Maneuver', Amount=1},
        },
    }
}
return TrustSettings

