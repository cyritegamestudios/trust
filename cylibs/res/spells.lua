-- Supplementary file to res/spells.lua

return T{
    [12] = {id=12,en="Raise",status=0,overwrites={}},
    [13] = {id=13,en="Raise II",status=0,overwrites={12}},
    [140] = {id=140,en="Raise III",status=0,overwrites={12,13}},
    [494] = {id=494,en="Arise",status=0,overwrites={12,13,140}},
    [125] = {id=125,en="Protectra",status=40,overwrites={}},
    [126] = {id=126,en="Protectra II",status=40,overwrites={125}},
    [127] = {id=127,en="Protectra III",status=40,overwrites={125,126}},
    [128] = {id=128,en="Protectra IV",status=40,overwrites={125,126,127}},
    [129] = {id=129,en="Protectra V",status=40,overwrites={125,126,127,128}},
    [130] = {id=130,en="Shellra",status=41,overwrites={}},
    [131] = {id=131,en="Shellra II",status=41,overwrites={130}},
    [132] = {id=132,en="Shellra III",status=41,overwrites={130,131}},
    [133] = {id=133,en="Shellra IV",status=41,overwrites={130,131,132}},
    [134] = {id=134,en="Shellra V",status=41,overwrites={130,131,132,133}},
    [108] = {id=108,en="Regen",status=42,overwrites={}},
    [109] = {id=109,en="Refresh",status=43,overwrites={}},
    [110] = {id=110,en="Regen II",status=42,overwrites={108}},
    [111] = {id=111,en="Regen III",status=42,overwrites={108,110}},
    [112] = {id=112,en="Flash",status=156,overwrites={}},
    [135] = {id=135,en="Reraise",status=113,overwrites={}},
    [141] = {id=141,en="Reraise II",status=113,overwrites={135}},
    [142] = {id=142,en="Reraise III",status=113,overwrites={135,141}},
    [242] = {id=242,en="Absorb-ACC",status=90},
    [246] = {id=246,en="Drain II",status=88},
    [266] = {id=266,en="Absorb-STR",status=119},
    [267] = {id=267,en="Absorb-DEX",status=120},
    [268] = {id=268,en="Absorb-VIT",status=121},
    [269] = {id=269,en="Absorb-AGI",status=122},
    [270] = {id=270,en="Absorb-INT",status=123},
    [271] = {id=271,en="Absorb-MND",status=124},
    [272] = {id=272,en="Absorb-CHR",status=125},
    [338] = {id=338,en="Utsusemi: Ichi",status=445,overwrites={36}},
    [339] = {id=339,en="Utsusemi: Ni",status=445,overwrites={36}},
    [340] = {id=340,en="Utsusemi: San",status=445,overwrites={36}},
    [473] = {id=473,en="Refresh II",status=43,overwrites={109}},
    [477] = {id=477,en="Regen IV",status=42,overwrites={108,110,111}},
    [493] = {id=493,en="Temper",status=432,overwrites={}},
    [504] = {id=504,en="Regen V",status=42,overwrites={108,110,111,477}},
    [848] = {id=848,en="Reraise IV",status=113,overwrites={135,141,142}},
    [855] = {id=855,en="Enlight II",status=274,overwrites={310}},
    [856] = {id=856,en="Endark II",status=288,overwrites={311}},
    [880] = {id=880,en="Drain III",status=88,overwrites={246}},
    [894] = {id=894,en="Refresh III",status=43,overwrites={109,473}},
    [895] = {id=895,en="Temper II",status=432,overwrites={493}},
}, {"id", "en", "status", "overwrites"}
