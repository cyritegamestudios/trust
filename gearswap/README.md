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

## To get 5 songs

This file is built around a 5-song burst (Honor March, Blade Madrigal,
Minuet III, IV, V) with two dummy songs in between — and that needs
**Daurdabla 99**:

- Without Daurdabla, a Bard can only keep 2 songs up (3 with Clarion Call).
- Daurdabla 99 raises the limit to 4.
- Clarion Call adds +1, making 5.

So Daurdabla 99 is required to reach the full 5 songs. Without it, the
dummy songs and the 5-song rotation in this file will not fit.

## Without Daurdabla

Trust checks your inventory when it loads and caps the song count from what
you actually own — there is no error and no churning, just fewer songs:

- **No extra-song instrument:** 2 songs (3 with Clarion Call)
- **Terpander / Blurred Harp / Blurred Harp +1 / Miracle Cheer:** 3 songs
  (4 with Clarion Call)
- **Daurdabla / Loughnashade:** 4 songs (5 with Clarion Call)

Without Daurdabla, the singer keeps the first songs in the list (Honor
March, Blade Madrigal) and stops there. The dummy songs never go off,
because there is no room under the cap for them. GearSwap is fine too —
it only tries to equip Daurdabla for the dummy songs, and since those are
never sung, that never triggers (and equipping an instrument you do not
own would just fail silently, leaving Gjallarhorn on).

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
