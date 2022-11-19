-- Default trust settings for RDM
TrustSettings = {
    SelfBuffs = L{
        Buff.new('Refresh'),
        Buff.new('Haste'),
        Spell.new('Stoneskin', L{})
    },
    PartyBuffs = L{
        Buff.new('Refresh', L{}, L{'DRK','PUP','PLD','BLU','BLM','RUN'}),
        Buff.new('Haste', L{}, L{'WAR','BRD','RUN','MNK','THF'}),
        Buff.new('Flurry', L{}, L{'RNG'}),
    },
}
return TrustSettings

