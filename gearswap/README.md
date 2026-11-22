# GearSwap — Bard (BRD.lua)

## Where to place it

Copy `BRD.lua` to your GearSwap data folder:

```
Windower/addons/gearswap/data/BRD.lua
```

On a default install that is:

```
C:\Windower4\addons\gearswap\data\BRD.lua
```

Then reload it in game with:

```
//gs r
```

The file must be named `BRD.lua` (the Bard job abbreviation) — GearSwap only
loads `data/<JOB>.lua`, so any other name will not be picked up.

## What this file is

`BRD.lua` is the current Bard GearSwap file (formerly BRD-29). It handles
TP gear, weaponskills, and song gear:

- Daurdabla only for the two dummy songs (Goblin Gavotte, Scop's Operetta);
  real songs keep their potency instrument (Gjallarhorn, Marsyas for
  Honor March).
- TP gear comes back 4 seconds after the last song finishes
  (`SONG_RETURN_DELAY = 4`), so the full 5-song burst lands in song gear.
- Carnage Elegy pulls with the Elegy set (`//gs c pull`); `//gs c tp`
  forces TP gear.

Edit only the section between the `EDIT HERE ONLY` lines at the top of the
file to change gear, then `//gs r` in game.
