-- Default trust settings for RDM
TrustSettings = {
    SelfBuffs = L{
        Buff.new('Refresh'),
        Buff.new('Haste'),
        Buff.new('Temper'),
        Spell.new('Gain-STR'),
        Spell.new('Phalanx')
    },
    PartyBuffs = L{
        Buff.new('Refresh', L{}, L{'DRK','PUP','PLD','BLU','BLM','BRD','GEO','SMN'}),
        Buff.new('Haste', L{}, job_util.melee_jobs()),
        Spell.new('Phalanx II', L{}, job_util.melee_jobs()),
        Buff.new('Flurry', L{}, L{'RNG'}),
    },
    Debuffs = L{
        Debuff.new('Distract')
    },
}
return TrustSettings

