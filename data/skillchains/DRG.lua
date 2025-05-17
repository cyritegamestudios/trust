-- Weapon skill settings file for DRG
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
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Polearm', L{}),
            CombatSkillSettings.new('Club', L{}),
            CombatSkillSettings.new('Staff', L{}),
        },
        JobAbilities = L{

        },
    }
}