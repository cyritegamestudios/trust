-- Default trust settings for SMN
TrustSettings = {
    Default = {
        PartyBuffs = L{
            {Avatar='Garuda', Buff='Haste', BloodPact='Hastega II'},
            {Avatar='Shiva', Buff='TP Bonus', BloodPact='Crystal Blessing'},
            {Avatar='Fenrir', Buff='Accuracy Boost', BloodPact='Ecliptic Howl'},
            {Avatar='Ifrit', Buff='Warcry', BloodPact='Crimson Howl'},
        },
        Skillchains = {
            defaultws = {'Garland of Bliss'},
            tpws = {},
            spamws = {'Garland of Bliss'},
            starterws = {'Garland of Bliss'},
            preferws = {'Garland of Bliss'},
            cleavews = {},
            amws = 'Garland of Bliss',
            petws = {'Flaming Crush'}
        },
    }
}
return TrustSettings

