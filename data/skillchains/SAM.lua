-- Weapon skill settings file for SAM
return {
    Version = 1,
    Default = {
        Skillchain = L{
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"skillchain"}),
        },
        Skills = L{
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Polearm', L{}),
            CombatSkillSettings.new('Great Katana', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Archery', L{}),
        },
    }
}