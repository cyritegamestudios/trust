-- Weapon skill settings file for WHM
return {
    Version = 1,
    Default = {
        Skillchain = L{
        },
        Blacklist = L{
        },
        Skills = L{
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Staff', L{}),
        },
    }
}