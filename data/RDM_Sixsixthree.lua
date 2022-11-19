-- Default trust settings for RDM
TrustSettings = {
    SelfBuffs = L{
        Buff.new('Refresh'),
        Buff.new('Haste'),
        --Spell.new('Stoneskin', L{}),
        Spell.new('Phalanx', L{}),
        Buff.new('Temper'),
        Spell.new('Gain-STR'),
        --Spell.new('Enblizzard')
    },
    PartyBuffs = L{
        Buff.new('Refresh', L{}, L{'DRK','PUP','PLD','BLU','BLM'}),
        Buff.new('Haste', L{}, job_util.melee_jobs()),
        Buff.new('Flurry', L{}, L{'RNG'}),
    },
    Debuffs = L{
        Debuff.new('Distract')
    }
}
return TrustSettings

