-- Weapon skill settings file for GEO
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
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Staff', L{}),
            CombatSkillSettings.new('Dagger', L{}),
        },
        JobAbilities = L{

        },
    }
}