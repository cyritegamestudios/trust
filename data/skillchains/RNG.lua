-- Weapon skill settings file for RNG
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
            CombatSkillSettings.new('Archery', L{}),
            CombatSkillSettings.new('Marksmanship', L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Axe', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
    }
}