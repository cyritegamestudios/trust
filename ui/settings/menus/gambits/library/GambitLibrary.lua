local GambitCategory = require('ui/settings/menus/gambits/library/GambitCategory')

return L{
    GambitCategory.new("Items", "Use items.", L{
        Gambit.new("Self", L{HasDebuffCondition.new("silence")}, UseItem.new("Echo Drops", L{ItemCountCondition.new("Echo Drops", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("poison")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("paralysis")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("doom")}, UseItem.new("Holy Water", L{ItemCountCondition.new("Holy Water", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("slow")}, UseItem.new("Panacea", L{ItemCountCondition.new("Panacea", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Reraise")}), ItemCountCondition.new("Hi-Reraiser", 1, ">=")}, UseItem.new("Hi-Reraiser", L{ItemCountCondition.new("Hi-Reraiser", 1, ">=")}), "Self", L{"Items"}),
    }),
    GambitCategory.new("Stackables", "Use toolbags, quivers, cases, etc.", L{
        Gambit.new("Self", L{ItemCountCondition.new("Shihei", 10, "<"), ItemCountCondition.new("Toolbag (Shihe)", 1, ">=")}, UseItem.new("Toolbag (Shihe)", L{ItemCountCondition.new("Toolbag (Shihe)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Inoshishinofuda", 10, "<"), ItemCountCondition.new("Toolbag (Ino)", 1, ">=")}, UseItem.new("Toolbag (Ino)", L{ItemCountCondition.new("Toolbag (Ino)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Shikanofuda", 10, "<"), ItemCountCondition.new("Toolbag (Shika)", 1, ">=")}, UseItem.new("Toolbag (Shika)", L{ItemCountCondition.new("Toolbag (Shika)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Chonofuda", 10, "<"), ItemCountCondition.new("Toolbag (Cho)", 1, ">=")}, UseItem.new("Toolbag (Cho)", L{ItemCountCondition.new("Toolbag (Cho)", 1, ">=")}), "Self", L{"Items", "Ninjutsu"}),
        Gambit.new("Self", L{ItemCountCondition.new("Trump Card", 10, "<")}, UseItem.new("Trump Card Case", L{ItemCountCondition.new("Trump Card Case", 1, ">=")}), "Self", L{"Items", "Cards"}),
    }),
    GambitCategory.new("Jug Pets", "Ready moves, blood pacts, etc.", L{
        Gambit.new("Self", L{ReadyChargesCondition.new(2, ">="), HasPetCondition.new(L{}), InBattleCondition.new()}, JobAbility.new("Tegmina Buffet", L{}, L{}), "Self", L{})
    })
}