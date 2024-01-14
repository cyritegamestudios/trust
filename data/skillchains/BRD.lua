-- Weapon skill settings file for BRD
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
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Staff', L{}),
        },
    }
}