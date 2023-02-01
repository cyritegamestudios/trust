-- Default trust settings for RDM
TrustSettings = {
    Default = {
        JobAbilities = L{
            'Composure'
        },
        SelfBuffs = L{
            Buff.new('Refresh'),
            Buff.new('Haste'),
            Buff.new('Temper', L{}, L{}, nil, L{ InBattleCondition.new() }),
            Spell.new('Enblizzard', L{}, L{}, nil, L{ InBattleCondition.new() }),
            Spell.new('Gain-INT', L{}, L{}, nil, L{ IdleCondition.new() }),
            Spell.new('Gain-STR', L{}, L{}, nil, L{ InBattleCondition.new() }),
            Spell.new('Phalanx'),
            Buff.new('Protect'),
            Buff.new('Shell')
        },
        PartyBuffs = L{
            Buff.new('Refresh', L{}, L{'DRK','PUP','PLD','BLU','BLM','BRD','GEO','SMN','WHM','RUN'}),
            Buff.new('Haste', L{}, job_util.melee_jobs():extend(L{'SCH','BLM'})),
            Buff.new('Haste', L{}, L{ 'COR' }, nil, L{ InBattleCondition.new() }),
            Buff.new('Flurry', L{}, L{'RNG','COR'}, nil, L{ IdleCondition.new() }),
            Spell.new('Phalanx II', L{}, job_util.melee_jobs(), nil, L{ InBattleCondition.new() }),
        },
        CureSettings = {
            Thresholds = {
                ['Default'] = 78,
                ['Emergency'] = 35,
                ['Cure IV'] = 1500,
                ['Cure III'] = 600,
                ['Cure II'] = 0
            }
        },
        Debuffs = L{
            Debuff.new('Distract'),
        },
        Skillchains = {
            defaultws = {'Savage Blade','Seraph Blade','Death Blossom','Black Halo'},
            tpws = {'Savage Blade'},
            spamws = {'Savage Blade','Black Halo'},
            starterws = {'Death Blossom','Savage Blade'},
            preferws = {'Death Blossom','Savage Blade','Black Halo','Realmrazer'},
            cleavews = {'Aeolian Edge'},
            amws = 'Death Blossom'
        },
        AutoFood = 'Grape Daifuku'
    },
}
return TrustSettings

