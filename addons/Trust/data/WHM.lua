-- Default trust settings for WHM
TrustSettings = {
    Default = {
        JobAbilities = L{
            'Afflatus Solace'
        },
        SelfBuffs = L{
            Buff.new('Haste'),
            Buff.new('Reraise'),
            Buff.new('Protectra'),
            Buff.new('Shellra'),
            Buff.new('Auspice'),
            Buff.new('Boost-STR'),
        },
        PartyBuffs = L{
            Buff.new('Haste', L{}, L{'WAR','MNK','THF','PLD','DRK','SAM','DRG','NIN','PUP','COR','DNC','BLU','RUN','BLM','BRD','BST'}),
            Buff.new('Protect', L{}, job_util.all_jobs()),
            Buff.new('Shell', L{}, job_util.all_jobs()),
        },
        CureSettings = {
            Thresholds = {
                ['Default'] = 78,
                ['Emergency'] = 40,
                ['Cure IV'] = 1500,
                ['Cure III'] = 600,
                ['Cure II'] = 0,
                ['Curaga III'] = 900,
                ['Curaga II'] = 600,
                ['Curaga'] = 0
            },
            StatusRemovals = {
                Blacklist = L{
                }
            }
        },
        Debuffs = L{
            Spell.new('Dia II')
        },
        Skillchains = {
            defaultws = {'Black Halo'},
            tpws = {},
            spamws = {'Black Halo'},
            starterws = {'Black Halo'},
            preferws = {'Black Halo'},
            cleavews = {},
            amws = 'Mystic Boon',
        },
    },
}
return TrustSettings

