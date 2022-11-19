# Trust

## Summary

The Trust addon turns your character into a Trust. It works for all jobs and takes
of things like attacking, nuking, pulling, skill chaining, tanking and more.

--------------------------------------------------------------------------------

## Setup

You will need the latest version of [trust](https://github.com/cyritegamestudios/trust), either by downloading the zip file on Github or cloning the repo.

1. Git clone or download [trust](https://github.com/cyritegamestudios/trust) from Github.
2. Copy the `cylibs` folder into your `Windower/addons/libs` folder. The hierarchy should be `Windower/addons/libs/cylibs`. Make sure you do not have two nested `cylibs` folders.
4. Copy the `Trust` and `follow` addon folders into your `Windower/addons` folder. The hierarchy should be `Windower/addons/Trust` and `Windower/addons/follow`.
5. Run `// lua r trust` and you're ready to get started!

### Optional

6. Override [job settings](#job-settings) to customize what your trust does.


## Dependencies

Currently, Trust depends on the following libraries and addons:

* Shortcuts
* Gearswap

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

There are over a dozen configurable Modes. To see the full list of Modes:

`// trust status`

## Settings

There are two layers of settings in Trust.

### Job Settings

The first one is job-specific settings and can be found in the
`Trust/data` folder (e.g. `RDM.lua`, `PUP.lua`, `WAR.lua`). These files specify behavior for their respective jobs. 
For example, settings in `RDM.lua` have two lists, `SelfBuffs` and `PartyBuffs`. Changing the values in these lists will 
change what buffs the RDM Trust applies to itself and its party.

Below are some examples of settings that can be configured:

| Syntax                                          | Example                                               | Description                                                                                                 |
|-------------------------------------------------|-------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| Spell.new(spell_name, job_abilities, job_names) | Spell.new('Refresh', L{'Composure'}, L{'BLU', 'WHM'}) | Casts a spell. Optionally uses a job ability before casting the spell. Optionally limits to specific jobs.  |
| Buff.new(buff_name, job_abilities, job_names)   | Buff.new('Refresh', L{}, L{'DRK','PUP','PLD'})        | Same as Spell, but automatically determines the highest tier version of the buff the Trust is able to cast. |

See the [wiki doc](../../libs/cylibs/doc/modules/Spell.html) in your browser for a more detailed description of Spells.

You can customize these settings by forking off of the default settings using the following command:

`// trust create JOB_NAME_SHORT`, e.g. `// trust create RDM`. This will create a copy of the default settings file with the format
`JOB_NAME_SHORT_character_name.lua`, e.g. `RDM_Avesta.lua`. Job settings will now reference this file instead while
you are on that character.

### Mode Settings

The second is Mode specific settings and can be found in `Trust/data/settings.xml`. You can use these to store values of Modes (e.g. `AutoBuffMode`, `AutoPullMode`, etc.) so you don't have to reset them every
time you reload the `Trust` addon. Default configurations are provided for each job and will automatically load when
loading the addon.

To load a specific configuration:

`// trust load configuration_name`, e.g. `// trust load dynamispup`.

To create a new configuration or override an existing configuration:

`// trust save configuration_name`, e.g. `// trust save dynamispup`.

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

| Command                          | Action                                                                                            |
|----------------------------------|---------------------------------------------------------------------------------------------------|
| // trust load configuration_name | Loads a configuration of Modes values.                                                            |
| // trust save configuration_name | Saves a configuration of Modes values.                                                            |
| // trust create job_name_short   | Creates a copy of the default job settings for the current character, e.g. `// trust create RDM`. |

### Debugging
| Debugging commands | Action                                                                   |
|------------------|--------------------------------------------------------------------------|
| // trust debug   | Will display a list of actions in the queue as well as basic debug info. |

## Modes
Modes control the behavior of the Trust. This is not an exhaustive list of Modes, however here are some of the
important ones and what they do.

| Mode             | Values                  | Description                                                                                                                                                                                                        |
|------------------|-------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AutoPullMode     | Off, Auto, Multi        | Pulls mobs using the job's default pulling ability or spell. Battle targets are specified in settings.xml. If `Multi`, will use `SmartTarget` logic and prioritize pulling different mobs than your party members. |
| AutoBuffMode     | Off, Auto               | Applies the buffs in the job settings file.                                                                                                                                                                        |
| AutoSongMode     | Off, Auto, Dummy        | Sings the songs specified in the job settings file. `Auto` will sing dummy songs as needed. `Dummy` will only sing dummy songs.                                                                                    |
| AutoDebuffMode   | Off, Auto               | Applies the debuffs in the job settings file.                                                                                                                                                                      |
| AutoSilenceMode  | Off, Auto               | Automatically casts silence when a mob finishes casting a spell.                                                                                                                                                   |
| AutoHealMode     | Off, Auto, Emergency    | Heals party members. If `Emergency`, only heals below 25% HP.                                                                                                                                                      |
| AutoRaiseMode    | Off, Auto               | Automatically raises a party member when they are KO'ed.                                                                                                                                                           |
| AutoEngageMode   | Off, Always, Assist     | If `Always`, engages the party's current target. If `Assist`, locks onto the target but does not engage.                                                                                                           |
| CombatMode       | Off, Melee, Ranged      | If `Melee`, will maintain a 3 yalm distance from the target. If `Ranged`, will maintain a 21 yalm distance from the target.                                                                                        |
| AutoFollowMode   | Off, Always             | Automatically follows the assist target after the current target dies.                                                                                                                                             |
| AutoManeuverMode | Off, Auto               | Automatically applies maneuvers specified in the job settings file.                                                                                                                                                |
| AutoFoodMode     | Off, Auto               | Automatically uses the food specified by `AutoFood` in the job settings file.                                                                                                                                      |
| AutoTrustsMode   | Off, Auto               | Automatically summons trusts when not in combat.                                                                                                                                                                   |
| AutoAssaultMode  | Off, Auto               | Automatically deploys, assaults, or fights your pet on the battle target.                                                                                                                                          |
| AutoPetMode      | Off, Auto               | Automatically summons an automaton or familiar.                                                                                                                                                                    |
| AutoAvatarMode   | Off, Ifrit, Shiva, etc. | Automatically summons an avatar.                                                                                                                                                                                   |
| AutoRollMode     | Off, Manual, Auto       | Automatically uses Phantom Roll. If `Manual`, the player must initiate the roll. If `Auto`, rolls in the job settings file will automatically be applied.                                                          |

To see the full list of Modes availabile on the player's current job, use `// trust status`.

You can combine these modes to customize Trust behavior. For example, to make your Trust assist a player named Bregor and automatically engage and approach the mob:

* `// trust assist Bregor`
* `// trust set AutoEngageMode Always`
* `// trust set CombatMode Melee`

## Remote Commands
You can execute commands remotely on a player using Trust. This allows you to do things like add yourself to the player's party, even if they are AFK.

### Whitelist
For safety reasons, you must be in a player's remote command whitelist in order to execute remote commands on their player. Additionally, there is a strict list of commands that are able to be executed.

### Remote Command List
To send a remote command, simply send the player a tell with one of the following commands.

| Command                            | Action                                                      |
|------------------------------------|-------------------------------------------------------------|
| Any [Trust command](#command-list) | E.g. `trust start`, `trust stop`.                           |
| /pcmd add player_name              | Adds a player to the party, e.g. `/pcmd add Jerry`.         |
| /pcmd remove player_name           | Removes a player from the party, e.g. `/pcmd remove Jerry`. |
| /warp                              | Warps (requires Gearswap warp ring/cudgel shortcut).        |
| /refa, /refa all                   | Dismisses a player's trusts.                                |

You can combine these commands to control another player's actions using Trust. For example, if you wanted to join an AFK master level party, you would do:

* `/t Ashylarry trust stop`
* `/t Ashylarry /refa all`
* `/t Ashylarry /pcmd add Jerry` (requires autojoin)
* `/t Ashylarry trust start`