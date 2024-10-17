local GambitCategory = require('ui/settings/menus/gambits/library/GambitCategory')

return L{
    GambitCategory.new("Items", "Use items.", L{
        Gambit.new("Self", L{HasDebuffCondition.new("silence")}, UseItem.new("Echo Drops", L{ItemCountCondition.new("Echo Drops", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("poison")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("paralysis")}, UseItem.new("Remedy", L{ItemCountCondition.new("Remedy", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("doom")}, UseItem.new("Holy Water", L{ItemCountCondition.new("Holy Water", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
        Gambit.new("Self", L{HasDebuffCondition.new("slow")}, UseItem.new("Panacea", L{ItemCountCondition.new("Panacea", 1, ">=")}), "Self", L{"Items", "Status Ailments"}),
    }),
}