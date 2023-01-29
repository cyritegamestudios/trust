-- Default trust settings for COR
TrustSettings = {
    Default = {
        Roll1=Roll.new("Chaos Roll", true),
        Roll2=Roll.new("Samurai Roll", false),
        Skillchains = {
            defaultws = {'Leaden Salute','Savage Blade'},
            tpws = {'Leaden Salute','Savage Blade'},
            spamws = {'Savage Blade'},
            starterws = {'Leaden Salute'},
            preferws = {'Leaden Salute','Savage Blade'},
            cleavews = {},
            amws = 'Leaden Salute'
        }
    }
}
return TrustSettings

