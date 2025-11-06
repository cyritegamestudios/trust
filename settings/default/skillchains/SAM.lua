-- Weapon skill settings file for SAM
return {
    Version = 1,
    Default = {
        Skillchain = {
            Gambits = L{
                Gambit.new("Enemy", L{}, WeaponSkill.new("Tachi: Fudo", L{}, L{}), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"}),
                Gambit.new("Enemy", L{}, SkillchainAbility.auto(), "Self", L{"Skillchain"})
            }
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