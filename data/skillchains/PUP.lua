-- Weapon skill settings file for PUP
return {
    Version = 1,
    Default = {
        Skillchain = L{
          WeaponSkill.new('Tornado Kick'),
          WeaponSkill.new('Shijin Spiral'),
          WeaponSkill.new('Shijin Spiral'),
          WeaponSkill.new('Victory Smite'),
        },
        Blacklist = L{
            'Water',
            'Fire',
        },
        Skills = L{
            CombatSkillSettings.new('Hand-to-Hand', L{ 'Combo', 'Shoulder Tackle' }),
            CombatSkillSettings.new('Dagger', L{}),
            CombatSkillSettings.new('Club', L{}),
        },
    }
}