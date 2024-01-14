-- Weapon skill settings file for NIN
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
            CombatSkillSettings.new('Hand-to-Hand', L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Katana', L{}),
            CombatSkillSettings.new('Great Katana', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Archery', L{}),
            CombatSkillSettings.new('Marksmanship', L{}),
        },
    }
}