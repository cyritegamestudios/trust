-- Settings file for PLD
return {
    ["Default"]={
        ["SelfBuffs"]={
            [1]={
                ["spell_name"]="Phalanx", 
                ["conditions"]={
                    ["n"]=0
                }, 
                ["type"]="Spell", 
                ["job_abilities"]={
                    ["n"]=0
                }
            }, 
            [2]={
                ["spell_name"]="Protect V", 
                ["conditions"]={
                    ["n"]=0
                }, 
                ["type"]="Spell", 
                ["job_abilities"]={
                    ["n"]=0
                }
            }, 
            ["n"]=2
        }, 
        ["PartyBuffs"]={
            ["n"]=0
        }, 
        ["JobAbilities"]={
            [1]="Majesty", 
            ["n"]=1
        }, 
        ["CureSettings"]={
            ["Thresholds"]={
                ["Cure IV"]=1000, 
                ["Cure II"]=0, 
                ["Default"]=78, 
                ["Emergency"]=25, 
                ["Cure III"]=400
            }, 
            ["Delay"]=2, 
            ["StatusRemovals"]={
                ["Blacklist"]={
                    ["n"]=0
                }
            }
        }, 
        ["Skillchains"]={
            ["spamws"]={
                [1]="Savage Blade", 
                [2]="Torcleaver"
            }, 
            ["cleavews"]={
                [1]="Circle Blade"
            }, 
            ["amws"]="Torcleaver", 
            ["preferws"]={
                [1]="Red Lotus Blade", 
                [2]="Torcleaver"
            }, 
            ["starterws"]={
                [1]="Red Lotus Blade"
            }, 
            ["defaultws"]={
                [1]="Savage Blade", 
                [2]="Torcleaver"
            }, 
            ["tpws"]={}
        }
    }
}