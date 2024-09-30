-- Weapon skill settings file for BST
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
            ReadyMoveSkillSettings.new(L{}),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Sword', L{}),
            CombatSkillSettings.new('Axe', L{}),
            CombatSkillSettings.new('Scythe', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
    }
}