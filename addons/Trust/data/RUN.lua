-- Default trust settings for RUN
TrustSettings = {
    Default = {
        SelfBuffs = S{
            Spell.new('Temper'),
            Spell.new('Crusade'),
            Spell.new('Refresh'),
            Spell.new('Regen IV'),
            Spell.new('Shell V'),
            Spell.new('Phalanx'),
        },
        PartyBuffs = S{
        },
        JobAbilities = S{
            'Swordplay'
        },
        Skillchains = {
            defaultws = {'Dimidiation','Steel Cyclone'},
            tpws = {},
            spamws = {'Dimidiation','Savage Blade'},
            starterws = {'Dimidiation'},
            preferws = {'Dimidiation','Savage Blade'},
            cleavews = {},
            amws = 'Dimidiation'
        },
    }
}
return TrustSettings

