-- Default trust settings for BST
TrustSettings = {
    Default = {
        JobAbilities = L{
            'Killer Instinct',
            'Spur'
        },
        SelfBuffs = L{
            { Familiar='VivaciousVickie', Buff='Counter Boost', ReadyMove='Zealous Snort' },
        },
        Skillchains = {
            defaultws = {'Decimation','Cloudsplitter'},
            tpws = {'Decimation','Cloudsplitter'},
            spamws = {'Cloudsplitter'},
            starterws = {},
            preferws = {'Decimation','Primal Rend','Cloudsplitter'},
            cleavews = {},
            amws = 'Primal Rend',
            petws = {'Pentapeck'},
        }
    }
}
return TrustSettings

