-- Weapon skill settings file for MNK
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
            CombatSkillSettings.new('Staff', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
        JobAbilities = L{

        },
    }
}