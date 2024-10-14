-- Weapon skill settings file for PLD
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
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Staff', L{}),
            CombatSkillSettings.new('Great Sword', L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Polearm', L{}),
        },
        JobAbilities = L{

        },
    }
}