-- Default trust settings for WAR
TrustSettings = {
    Default = {
        JobAbilities = L{
            'Berserk',
            'Aggressor',
            'Warcry',
            'Restraint',
            'Blood Rage',
            'Retaliation'
        },
        Skillchains = {
            defaultws = {'Full Break',"King's Justice",'Upheaval',"Ukko's Fury",'Savage Blade','Impulse Drive'},
            tpws = {},
            spamws = {'Impulse Drive','Upheaval','Savage Blade','Judgment'},
            starterws = {'Full Break'},
            preferws = {"King's Justice",'Steel Cyclone','Upheaval','Savage Blade','Full Break','Impulse Drive'},
            cleavews = {'Fell Cleave'},
            amws = "King's Justice"
        },
    }
}
return TrustSettings