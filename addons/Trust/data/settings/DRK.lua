-- Settings file for DRK
return {
    ["Default"]={
        ["Skillchains"]={
            ["spamws"]={
                [1]="Catastrophe", 
                [2]="Torcleaver", 
                [3]="Cross Reaper", 
                [4]="Entropy", 
                [5]="Judgment", 
                [6]="Savage Blade"
            }, 
            ["cleavews"]={
                [1]="Fell Cleave"
            }, 
            ["amws"]="Entropy", 
            ["preferws"]={
                [1]="Cross Reaper", 
                [2]="Catastrophe", 
                [3]="Torcleaver"
            }, 
            ["starterws"]={
                [1]="Torcleaver", 
                [2]="Catastrophe", 
                [3]="Cross Reaper", 
                [4]="Entropy"
            }, 
            ["defaultws"]={
                [1]="Cross Reaper", 
                [2]="Catastrophe", 
                [3]="Insurgency", 
                [4]="Entropy", 
                [5]="Torcleaver"
            }, 
            ["tpws"]={
                [1]="Cross Reaper"
            }
        }, 
        ["SelfBuffs"]={
            [1]={
                ["spell_name"]="Endark II", 
                ["conditions"]={
                    ["n"]=0
                }, 
                ["type"]="Spell", 
                ["job_abilities"]={
                    ["n"]=0
                }
            }, 
            [2]={
                ["spell_name"]="Absorb-DEX", 
                ["job_abilities"]={
                    ["n"]=0
                }, 
                ["job_names"]={
                    ["n"]=0
                }, 
                ["target"]="bt", 
                ["type"]="Spell", 
                ["conditions"]={
                    ["n"]=0
                }
            }, 
            [3]={
                ["spell_name"]="Absorb-STR", 
                ["job_abilities"]={
                    ["n"]=0
                }, 
                ["job_names"]={
                    ["n"]=0
                }, 
                ["target"]="bt", 
                ["type"]="Spell", 
                ["conditions"]={
                    ["n"]=0
                }
            }, 
            [4]={
                ["spell_name"]="Dread Spikes", 
                ["job_names"]={
                    ["n"]=0
                }, 
                ["job_abilities"]={
                    ["n"]=0
                }, 
                ["type"]="Spell", 
                ["conditions"]={
                    [1]={
                        ["buff_name"]="Max HP Boost", 
                        ["type"]="HasBuffCondition"
                    }, 
                    [2]={
                        ["type"]="IdleCondition"
                    }, 
                    ["n"]=2
                }
            }, 
            ["n"]=4
        }, 
        ["JobAbilities"]={
            [1]="Last Resort", 
            [2]="Scarlet Delirium", 
            ["n"]=2
        }
    }
}