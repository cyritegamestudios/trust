-- Weapon skill settings file for SAM
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
            CombatSkillSettings.new('Polearm', L{}),
            CombatSkillSettings.new('Great Katana', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Archery', L{}),
        },
        JobAbilities = L{
            JobAbility.new("Sekkanoki", L{MinTacticalPointsCondition.new(1500), SkillchainWindowCondition.new(3, ">=")}),
            JobAbility.new("Sengikori", L{MinTacticalPointsCondition.new(1000), SkillchainWindowCondition.new(3.5, ">="), SkillchainStepCondition.new(1, ">")})
        },
    }
}