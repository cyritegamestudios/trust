-- Default trust settings for RUN
TrustSettings = {
    SelfBuffs = S{
        Spell.new('Temper', L{}),
        Spell.new('Crusade', L{}),
        Spell.new('Refresh', L{}),
        --Spell.new('Regen IV', L{}),
        Spell.new('Shell V', L{}),
        Spell.new('Phalanx', L{}),
    },
    PartyBuffs = S{
    },
    JobAbilities = S{
        'Swordplay'
    }
}
return TrustSettings

