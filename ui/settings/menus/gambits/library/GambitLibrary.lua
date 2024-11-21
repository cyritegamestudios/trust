local GambitCategory = require('ui/settings/menus/gambits/library/GambitCategory')

return L{
    GambitCategory.new("Abilities", "Use abilities.", L{
        Gambit.new("Self", L{MaxTacticalPointsCondition.new(900), HasBuffsCondition.new(L{"Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1)}, JobAbility.new("Reverse Flourish", L{}, L{}), "Self", L{"Abilities"}),
        Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto")}, JobAbility.new("Double Shot", L{}, L{}), "Self", L{"Abilities"}),
        Gambit.new("Self", L{ModeCondition.new("AutoShootMode", "Auto")}, JobAbility.new("Velocity Shot", L{}, L{}), "Self", L{"Abilities"}),
    }),
    GambitCategory.new("Enemies", "React to enemies.", L{
        Gambit.new("Enemy", L{ReadyAbilityCondition.new("Dancing Fullers")}, RunAway.new(12, L{}), "Enemy", L{"Enemies","Reaction"}),
        Gambit.new("Enemy", L{FinishAbilityCondition.new("Dancing Fullers")}, RunTo.new(3, L{}), "Enemy", L{"Enemies","Reaction"}),
        Gambit.new("Self", L{TargetNameCondition.new("Dhartok"), NotCondition.new(L{ModeCondition.new("AutoMagicBurstMode", "Earth")})}, Command.new("// trust mb earth", L{}), "Self", L{"Enemies","Reaction"}),
        Gambit.new("Self", L{TargetNameCondition.new("Ghatjot"), NotCondition.new(L{ModeCondition.new("AutoMagicBurstMode", "Earth")})}, Command.new("// trust mb earth", L{}), "Self", L{"Enemies","Reaction"}),
    }),
    GambitCategory.new("Items", "Use items.", L{
        Gambit.new("Self", L{HasDebuffCondition.new("silence")}, UseItem.new("Echo Drops", L{ItemCountCondition.new("Echo Drops", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("poison")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("paralysis")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("doom")}, UseItem.new("Holy Water", L{ItemCountCondition.new("Holy Water", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("slow")}, UseItem.new("Panacea", L{ItemCountCondition.new("Panacea", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Reraise")})}, UseItem.new("Hi-Reraiser", L{ItemCountCondition.new("Hi-Reraiser", 1, ">=")}), "Self", L{"Items"}),
        Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Reraise")})}, UseItem.new("Super Reraiser", L{ItemCountCondition.new("Super Reraiser", 1, ">=")}), "Self", L{"Items"})
    }),
    GambitCategory.new("Jug Pets", "Ready moves, blood pacts, etc.", L{
        Gambit.new("Self", L{ReadyChargesCondition.new(2, ">="), HasPetCondition.new(L{}), InBattleCondition.new()}, JobAbility.new("Tegmina Buffet", L{}, L{}), "Self", L{}, L{"JugPet"}),
        Gambit.new("Self", L{NotCondition.new(L{HasBuffsCondition.new(L{"Counter Boost", "Magic Def. Boost"}, 1)}), InBattleCondition.new(), HasPetCondition.new(L{"VivaciousVickie"}), ModeCondition.new("AutoBuffMode", "Auto")}, JobAbility.new("Zealous Snort", L{}, L{}), "Self", L{"JugPet"}),
    }),
    GambitCategory.new("Spells", "Cast spells.", L{
        Gambit.new("Enemy", L{MaxManaPointsPercentCondition.new(40)}, Spell.new("Aspir", L{}, L{}, nil, L{}), "Self", L{"Spells"}),
        Gambit.new("Enemy", L{MaxManaPointsPercentCondition.new(40)}, Spell.new("Aspir II", L{}, L{}, nil, L{}), "Self", L{"Spells"}),
        Gambit.new("Enemy", L{MaxManaPointsPercentCondition.new(40)}, Spell.new("Aspir III", L{}, L{}, nil, L{}), "Self", L{"Spells"}),
        Gambit.new("Ally", L{MaxHitPointsPercentCondition.new(40)}, Spell.new("Cure III", L{}, L{}, nil, L{}), "Ally", L{}),
        Gambit.new("Ally", L{MaxHitPointsPercentCondition.new(40)}, Spell.new("Cure IV", L{}, L{}, nil, L{}), "Ally", L{}),
    }),
    GambitCategory.new("Stackables", "Use toolbags, quivers, cases, etc.", L{
        Gambit.new("Self", L{ItemCountCondition.new("Shihei", 10, "<"), ItemCountCondition.new("Toolbag (Shihe)", 1, ">=")}, UseItem.new("Toolbag (Shihe)", L{ItemCountCondition.new("Toolbag (Shihe)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Inoshishinofuda", 10, "<"), ItemCountCondition.new("Toolbag (Ino)", 1, ">=")}, UseItem.new("Toolbag (Ino)", L{ItemCountCondition.new("Toolbag (Ino)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Shikanofuda", 10, "<"), ItemCountCondition.new("Toolbag (Shika)", 1, ">=")}, UseItem.new("Toolbag (Shika)", L{ItemCountCondition.new("Toolbag (Shika)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Chonofuda", 10, "<"), ItemCountCondition.new("Toolbag (Cho)", 1, ">=")}, UseItem.new("Toolbag (Cho)", L{ItemCountCondition.new("Toolbag (Cho)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Trump Card", 10, "<")}, UseItem.new("Trump Card Case", L{ItemCountCondition.new("Trump Card Case", 1, ">=")}), "Self", L{"Items", "Cards"}),
        Gambit.new("Self", L{ItemCountCondition.new("Sarama's Coffer", 1, ">=")}, UseItem.new("Sarama's Coffer", L{ItemCountCondition.new("Sarama's Coffer", 1, ">=")}), "Self", L{}),
    }),
    GambitCategory.new("Weaponskills", "Use weapon skills.", L{
        Gambit.new("Enemy", L{NotCondition.new(L{HasDebuffCondition.new("Defense Down")}), InBattleCondition.new()}, WeaponSkill.new("Armor Break", L{MinTacticalPointsCondition.new(1000)}), "Enemy", L{"Weaponskills"}),
        Gambit.new("Enemy", L{NotCondition.new(L{HasDebuffCondition.new("Defense Down")}), InBattleCondition.new()}, WeaponSkill.new("Full Break", L{MinTacticalPointsCondition.new(1000)}), "Enemy", L{"Weaponskills"})
    }),
}