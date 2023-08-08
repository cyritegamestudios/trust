# Trust

## Summary

Trust is a Windower 4 addon for FFXI that turns your character into a Trust. It works for all jobs and can attack, nuke, pull, skillchain and more.

--------------------------------------------------------------------------------

## Support

Get help or request a feature in the [Cyrite Game Studios Discord](https://discord.gg/rUa52rWK). Do NOT ask questions about Trust in game.

## Setup

You will need the latest version of [Trust](https://github.com/cyritegamestudios/trust) in order to use Trust. You will need to update *both* the `addons` and `cylibs` repo when you pull new changes, as `addons` is powered by `cylibs` and will not work properly if the versions don't match.

1. Git clone or download [Trust](https://github.com/cyritegamestudios/trust) from Github.
2. Copy the `addons` folder into your `Windower` folder so that you are pasting the new `addons` folder on top of your existing `addons` folder. Note that this will *not* override your entire existing `addons` folder, only addons related to Trust.
3. Double check that the `Windower/addons/Trust` folder exists.
5. Double check that the `Windower/addons/libs/cylibs` folder exists.
6. Run `// lua r trust` and you're ready to get started!

## Updates

To update Trust, either do a `git pull --rebase` or follow the steps above again.

### Optional

6. Override [job settings](#job-settings) to customize what your trust does.

## Dependencies

Trust also requires the following libraries and addons:
* Shortcuts
* Gearswap (vanilla or Selendrile)

## Modes

Trusts uses Modes inspired by GearSwap to control Trust behavior. For example,
`AutoPullMode` controls whether the Trust should pull mobs:

`state.AutoPullMode = M{['description'] = 'Auto Pull Mode', 'Off', 'Auto'}`

When set to `Auto`, the Trust will automatically start pulling mobs specified in
the `battle_targets` list in settings.xml.

To cycle between Modes:

`// trust cycle AutoPullMode`

To set the value of a Mode directly:

`// trust set AutoPullMode Auto`

There are over a dozen configurable Modes. To see the full list of Modes available on your current job:

`// trust status`

## Settings

Settings determine the behavior of a Trust and can be configured in two different ways:

### Job Settings

These settings are job-specific settings and can be found in the
`Trust/data` folder (e.g. `RDM.lua`, `PUP.lua`, `WAR.lua`). These files specify behavior for their respective jobs. 
For example, settings in `RDM.lua` have two lists, `SelfBuffs` and `PartyBuffs`. Changing the values in these lists will 
change what buffs the RDM Trust applies to itself and its party.

Below are some examples of job-specific settings that can be configured:

| Syntax                                          | Example                                               | Description                                                                                                 |
|-------------------------------------------------|-------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| Spell.new(spell_name, job_abilities, job_names) | Spell.new('Refresh', L{'Composure'}, L{'BLU', 'WHM'}) | Casts a spell. Optionally uses a job ability before casting the spell. Optionally limits to specific jobs.  |
| Buff.new(buff_name, job_abilities, job_names)   | Buff.new('Refresh', L{}, L{'DRK','PUP','PLD'})        | Same as Spell, but automatically determines the highest tier version of the buff the Trust is able to cast. |

Click on the [wiki doc](../../libs/cylibs/doc/modules/Spell.html) in your local file browser for a more detailed description of spells and buffs.

You can customize these settings by forking off of the default settings using the following command:

`// trust create JOB_NAME_SHORT`, e.g. `// trust create RDM`. This will create a copy of the default settings file with the format
`JOB_NAME_SHORT_character_name.lua`, e.g. `RDM_Avesta.lua`. Job settings will now reference this file instead while
you are on that character.

### Mode Settings

These settings are Mode-specific settings and can be found in the `Trust/data/modes` folder. You can use these to store values of Modes (e.g. `AutoBuffMode`, `AutoPullMode`, etc.) so you don't have to reset them every
time you reload the `Trust` addon. Default configurations are provided for each job and will *automatically load* when
loading the addon.

You can customize the default modes for a job by forking off of the default configuration:

Change your settings using the [modes commands](#command-list) and type `// trust save`. This will create a new copy of the modes configuration file with the format `JOB_NAME_SHORT_character_name.lua`, e.g. `RDM_Avesta.lua`. Modes configuration will now reference this file instead while
you are on that character. To save a new configuration instead of overriding the default configuration for the job, type `// trust save mode_name`, e.g. `// trust save Dynamis`.

You can cycle through all Mode settings for a job using `// trust cycle TrustMode`.

## Command List
### General

| Command                           | Action                                                             |
|-----------------------------------|--------------------------------------------------------------------|
| // trust start                    | Enables Trust.                                                     |
| // trust stop                     | Disables Trust. The Trust will stop performing actions.            |
| // trust reload                   | Reloads the addon and resets all loaded settings to the default.   |
| // trust assist party_member_name | Assists the specified party member, e.g. `// trust assist Wapiti`. |

### Modes

| Command                           | Action                                                                            |
|-----------------------------------|-----------------------------------------------------------------------------------|
| // trust cycle mode_name          | Cycles through possible values for a Mode, e.g. `// trust cycle AutoManeuverMode` |
| // trust set mode_name mode_value | Sets a Mode to a specific value, e.g. `// trust set AutoManeuverMode Auto`.       |
| // trust status                   | Outputs a list of current Modes and their values.                                 |

### Settings

| Command                        | Action                                                                                                                                                               |
|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| // trust save mode_name        | Saves a configuration of Modes values for the current job. If `mode_name` is specified, creates a new configuration. Otherwise, overrides the default configuration. |
| // trust create job_name_short | Creates a copy of the default job settings for the current character, e.g. `// trust create RDM`.                                                                    |
| // trust cycle TrustMode       | Cycles through all trust modes created with `// trust save mode_name`                                                                                                |

### Debugging
| Debugging commands | Action                                                                   |
|------------------|--------------------------------------------------------------------------|
| // trust debug   | Will display a list of actions in the queue as well as basic debug info. |

## Modes
Modes control the behavior of the Trust. This is not an exhaustive list of Modes, however here are some of the
important ones and what they do.

| Mode                   | Values                  | Description                                                                                                                                                                                                        |
|------------------------|-------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AutoPullMode           | Off, Auto, Multi        | Pulls mobs using the job's default pulling ability or spell. Battle targets are specified in settings.xml. If `Multi`, will use `SmartTarget` logic and prioritize pulling different mobs than your party members. |
| AutoBuffMode           | Off, Auto               | Applies the buffs in the job settings file.                                                                                                                                                                        |
| AutoSongMode           | Off, Auto, Dummy        | Sings the songs specified in the job settings file. `Auto` will sing dummy songs as needed. `Dummy` will only sing dummy songs.                                                                                    |
| AutoDebuffMode         | Off, Auto               | Applies the debuffs in the job settings file.                                                                                                                                                                      |
| AutoSilenceMode        | Off, Auto               | Automatically casts silence when a mob finishes casting a spell.                                                                                                                                                   |
| AutoHealMode           | Off, Auto, Emergency    | Heals party members. If `Emergency`, only heals below 25% HP.                                                                                                                                                      |
| AutoRaiseMode          | Off, Auto               | Automatically raises a party member when they are KO'ed.                                                                                                                                                           |
| AutoEngageMode         | Off, Always, Assist     | If `Always`, engages the party's current target. If `Assist`, locks onto the target but does not engage.                                                                                                           |
| CombatMode             | Off, Melee, Ranged      | If `Melee`, will maintain a 3 yalm distance from the target. If `Ranged`, will maintain a 21 yalm distance from the target.                                                                                        |
| AutoFollowMode         | Off, Always             | Automatically follows the assist target after the current target dies.                                                                                                                                             |
| AutoManeuverMode       | Off, Auto               | Automatically applies maneuvers specified in the job settings file.                                                                                                                                                |
| AutoFoodMode           | Off, Auto               | Automatically uses the food specified by `AutoFood` in the job settings file.                                                                                                                                      |
| AutoTrustsMode         | Off, Auto               | Automatically summons trusts when not in combat.                                                                                                                                                                   |
| AutoAssaultMode        | Off, Auto               | Automatically deploys, assaults, or fights your pet on the battle target.                                                                                                                                          |
| AutoPetMode            | Off, Auto               | Automatically summons an automaton or familiar.                                                                                                                                                                    |
| AutoAvatarMode         | Off, Ifrit, Shiva, etc. | Automatically summons an avatar.                                                                                                                                                                                   |
| AutoRollMode           | Off, Manual, Auto       | Automatically uses Phantom Roll. If `Manual`, the player must initiate the roll. If `Auto`, rolls in the job settings file will be initiated automatically.                                                        |
| AutoSkillchainMode     | Off, Auto, Cleave, Spam | Automatically performs skillchains. If `Cleave`, will spam AOE weaopn skills. If `Spam`, will spam a single weapon skill instead of making skillchains.                                                            |
| SkillchainPriorityMode | Off, Prefer, Strict     | If `Prefer`, will perform weapon skills specified in `preferws` in the job settings file when possible. If `Strict`, will only perform those weapon skills.                                                        |
| AutoMagicBurstMode     | Off, Auto               | If `Auto`, will attempt to magic burst skillchains.                                                                                                                                                                |

To see the full list of Modes availabile on the player's current job, use `// trust status`.

You can combine these modes to customize Trust behavior. For example, to make your Trust assist a player named Jerry and automatically engage and approach the mob:

* `// trust assist Jerry`
* `// trust set AutoEngageMode Always`
* `// trust set CombatMode Melee`

## Shortcuts
There are several built-in shortcuts that can make things like cycling between modes easier. The syntax is `// trust`, followed by a category of commands, and then one or more arguments, e.g. `// trust sc auto` will toggle between`AutoSkillchainMode` `Auto` and `Off`.

### Skillchains
| Command             | Action                                                            |
|---------------------|-------------------------------------------------------------------|
| // trust sc auto    | Short for `// trust set AutoSkillchainMode` `Auto` or `Off`       |
| // trust sc spam    | Short for `// trust set AutoSkillchainMode` `Spam` or `Off`       |
| // trust sc cleave  | Short for `// trust set AutoSkillchainMode` `Cleave` or `Off`     |
| // trust sc am      | Short for `// trust set AutoAftermathMode` `Auto` or `Off`        |
| // trust sc partner | Short for `// trust set SkillchainPartnerMode` `Auto` or `Off`    |
| // trust sc open    | Short for `// trust set SkillchainPartnerMode` `Open` or `Off`    |
| // trust sc close   | Short for `// trust set SkillchainPartnerMode` `Close` or `Off`   |
| // trust sc prefer  | Short for `// trust set SkillchainPriorityMode` `Prefer` or `Off` |
| // trust sc strict  | Short for `// trust set SkillchainPriorityMode` `Strict` or `Off` |

### Battle
| Command                | Action                                                            |
|------------------------|-------------------------------------------------------------------|
| // trust pull auto     | Short for `// trust set AutoPullMode` `Auto` or `Off`             |
| // trust pull multi    | Short for `// trust set AutoPullMode` `Multi` or `Off`            |
| // trust pull target   | Short for `// trust set AutoPullMode` `Target` or `Off`           |
| // trust engage auto   | Short for `// trust set AutoEngageMode` `Always` or `Off`         |
| // trust engage assist | Short for `// trust set AutoEngageMode` `Assist` or `Off`         |

## Remote Commands
You can execute commands remotely on a player using Trust. This allows you to do things like add yourself to the player's party, even if they are AFK.

### Whitelist
For safety reasons, you must be in a player's remote command whitelist in order to execute remote commands on their player. Additionally, there is a strict list of commands that are able to be executed.

### Remote Command List
To send a remote command, send the player a tell with one of the following commands.

| Command                            | Action                                                      |
|------------------------------------|-------------------------------------------------------------|
| Any [Trust command](#command-list) | E.g. `trust start`, `trust stop`.                           |
| /pcmd add player_name              | Adds a player to the party, e.g. `/pcmd add Jerry`.         |
| /pcmd remove player_name           | Removes a player from the party, e.g. `/pcmd remove Jerry`. |
| /warp                              | Warps (requires Gearswap warp ring/cudgel shortcut).        |
| /refa, /refa all                   | Dismisses a player's trusts.                                |

You can combine these commands to control another player's actions using Trust. For example, if you wanted to join a party, you would do:

* `/t Ashylarry trust stop`
* `/t Ashylarry /refa all`
* `/t Ashylarry /pcmd add Jerry` (requires autojoin)
* `/t Ashylarry trust start`

v1.0.8
