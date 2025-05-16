-- Weapon skill settings file for DNC
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
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Hand-to-Hand', L{}),
            CombatSkillSettings.new('Sword', L{}),
        },
        JobAbilities = L{
            JobAbility.new("Building Flourish", L{SkillchainWindowCondition.new(3, ">="), SkillchainStepCondition.new(1, ">="), HasBuffsCondition.new(L{"Finishing Move 1", "Finishing Move 2", "Finishing Move 3", "Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1)}, L{}),
            JobAbility.new("Climactic Flourish", L{SkillchainWindowCondition.new(3.5, ">="), SkillchainStepCondition.new(1, ">"), HasBuffsCondition.new(L{"Finishing Move 1", "Finishing Move 2", "Finishing Move 3", "Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"}, 1)}, L{})
        },
    }
}