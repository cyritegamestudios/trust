-- Weapon skill settings file for RUN
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
            CombatSkillSettings.new('Great Sword', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Great Axe', L{}),
            CombatSkillSettings.new('Axe', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
        JobAbilities = L{

        },
    }
}