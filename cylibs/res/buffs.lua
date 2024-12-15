-- Supplementary file to res/buffs.lua

return T{
    [391] = {id=391,en="Sluggish Daze 1",overwrites={}},
    [392] = {id=392,en="Sluggish Daze 2",overwrites={391}},
    [393] = {id=393,en="Sluggish Daze 3",overwrites={391,392}},
    [394] = {id=394,en="Sluggish Daze 4",overwrites={391,392,393}},
    [395] = {id=395,en="Sluggish Daze 5",overwrites={391,392,393,394}},
    [700] = {id=700,en="Sluggish Daze 6",overwrites={391,392,393,394}},
    [701] = {id=701,en="Sluggish Daze 7",overwrites={391,392,393,394,700}},
    [702] = {id=702,en="Sluggish Daze 8",overwrites={391,392,393,394,700,701}},
    [703] = {id=703,en="Sluggish Daze 9",overwrites={391,392,393,394,700,702}},
    [704] = {id=704,en="Sluggish Daze 10",overwrites={391,392,393,394,700,701,702,703}},
}, {"id", "en", "overwrites"}