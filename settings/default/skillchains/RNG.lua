-- Weapon skill settings file for RNG
return {
    Version = 1,
    Default = {
        Skillchain = {
            Gambits = L{
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            }
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