-- Settings file for MON
return {
    Version = 1,
    Default = {
        RoleSettings = {
            Priority = L{
                'puller',
                'reacter',
                'gambiter',
                'attacker',
                'combatmode',
                'follower',
                'pather',
                'skillchainer',
                'spammer',
                'cleaver',
                'truster',
                'aftermather',
            }
        },
        CombatSettings = {
            Distance = 2,
            EngageDistance = 30,
            MirrorDistance = 0.5,
        },
        GambitSettings = {
            Default = L{

            },
            Gambits = L{
            }
        },
        PullSettings = {
            Abilities = L{
            },
            Targets = L{
            },
            Blacklist = L{

            },
            Distance = 20
        },
        TargetSettings = {
            Retry = true
        },
    }
}
