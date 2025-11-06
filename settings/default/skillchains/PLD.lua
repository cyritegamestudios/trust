-- Weapon skill settings file for PLD
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
            CombatSkillSettings.new('Staff', L{}),
            CombatSkillSettings.new('Great Sword', L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Polearm', L{}),
        },
        JobAbilities = L{

        },
    }
}