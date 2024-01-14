-- Weapon skill settings file for PUP
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
            CombatSkillSettings.new('Hand-to-Hand', WeaponSkill.new('Tornado Kick'), L{ 'Combo', 'Shoulder Tackle' }),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
    }
}