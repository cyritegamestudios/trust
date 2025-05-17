-- Weapon skill settings file for BLU
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
        Blacklist = L{
        },
        Skills = L{
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
        JobAbilities = L{

        },
    }
}