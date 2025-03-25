-- Weapon skill settings file for WAR
return {
    Version = 1,
    Default = {
        Skillchain = L{
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
            Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
        },
        Skills = L{
            CombatSkillSettings.new('Great Axe', L{}),
            CombatSkillSettings.new('Axe', L{}),
            CombatSkillSettings.new('Great Sword', L{}),
            CombatSkillSettings.new('Scythe', L{}),
            CombatSkillSettings.new('Staff', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Polearm', L{}),
            CombatSkillSettings.new('Hand-to-Hand', L{}),
            CombatSkillSettings.new('Archery', L{}),
            CombatSkillSettings.new('Marksmanship', L{}),
        },
    }
}