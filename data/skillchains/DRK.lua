-- Weapon skill settings file for DRK
return {
    Version = 1,
    Default = {
        Skillchain = L{
            SkillchainAbility.auto(),
            SkillchainAbility.auto(),
            SkillchainAbility.auto(),
            SkillchainAbility.auto(),
            SkillchainAbility.auto(),
            SkillchainAbility.auto(),
        },
        Blacklist = L{
        },
        Skills = L{
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Great Sword', L{}),
            CombatSkillSettings.new('Axe', L{}),
            CombatSkillSettings.new('Great Axe', L{}),
            CombatSkillSettings.new('Scythe', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Marksmanship', L{}),
        },
    }
}