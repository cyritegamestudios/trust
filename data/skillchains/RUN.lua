-- Weapon skill settings file for RUN
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