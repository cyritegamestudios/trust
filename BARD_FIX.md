# Trust — Bard Fix

**Branch:** `brd-soul-voice-toggle` (fork of cyritegamestudios/trust) · **PR #577** · 88 commits · base: stock Trust v17.7.8

One package that turns stock Trust into a coordinated Bard farming machine. The whole fight loop — summon all five Trusts, sing the five-song burst at full potency, then pull — runs as one system: the singer, puller, attacker, debuffer and spammer all watch the same TP and singing state, so a weaponskill is never wasted, a burst never starts at the wrong moment, and no cast collides with another action's lock. Everything is scoped to attended play — it coordinates what the player is already doing; nothing runs unattended.

The per-fix record (what each bug was, how each fix was verified) lives in the commit history of PR #577. This bundle is that branch assembled: the complete addon, every fix already applied, one install.

## Install

1. Extract so the `trust` folder lands in `Windower\addons\` (back up your current `addons\trust` first).
2. In game: `//lua load trust`
3. Set CombatMode with the command, not the menu: `//trust set CombatMode Auto`
4. After the first install, run `//trust brd clear` once so the song tracker starts from a clean slate.

The matching GearSwap file is `gearswap/BRD.lua` in this repo (install as `gearswap/data/BRD.lua`, then `//gs r`).

## The burst

Order: Honor March (Marcato, Marsyas), Victory March, Valor Minuet IV, the two Daurdabla dummies (Goblin Gavotte, Scop's Operetta), Valor Minuet V, Blade Madrigal (Gjallarhorn). Minuet V and Madrigal overwrite the dummies. The burst re-sings as a unit — when the first song comes due, all five refresh together on one clock.

Boosters, as one system:
- Soul Voice never fires alone — it always goes out with Nightingale + Troubadour (and Clarion Call when a fifth slot is open).
- A combo that comes off cooldown mid-burst waits and leads the next burst instead of firing into the current one.
- Marcato is paired with Nitro and never spent under Soul Voice (it does not stack — under Soul Voice its boost is capped and its duration bonus cancelled). Spent on plain bursts, its 10-minute recast desynced from Nitro's; now it fires on Honor March inside Nitro bursts only.
- After the last combo ability lands, the first song waits out a 2-second grace so it never casts into the ability's tail ("Unable to cast at this time").

## The ordering rules (the holds chain)

- A banked weaponskill goes first: at 500+ TP, songs, debuffs, claims and new engages all wait; Nitro combos additionally require TP ≤ 999, so Nitro is never spent while a weaponskill is waiting.
- Once Nitro has gone off, that burst finishes first: the singer sings it through, and the weaponskill waits until the burst completes.
- The weaponskill is saved on a mob under 3% HP, held until the player reaches the fight's rolled combat distance, and never fired mid-song.
- Debuffs hold while singing, while a burst is pending, and for 2 seconds after a weaponskill lands; casts hold the same 2 seconds, so nothing collides with the weaponskill's action lock.
- The puller claims the mob in front of the player first; a mob behind is the second option — except a mob already aggroed on the party (a slept add keeps that status), which is never filtered out and is attacked next when the fought mob dies.

## What is Bard, and what is every job

- **Bard:** the singer and burst, the song tracker's timer handling (including the two Marches, whose shared buff timers can no longer be paired to the wrong song), dummy songs, the Nitro system, the Marcato rules.
- **Every job:** front-first claiming and engage-claims, the weaponskill distance gate and 3% save, SpellAction waiting out the weaponskill lock for every spell, the 2-second wait after a spell's job abilities, casts not chasing the mob, the rolled combat distance and backpedal, the core audit (leaks, nil guards, queue protection), the menu background fix, the double raise-accept fix, debuffs remembered across a reload, and one Scholar strategem fix.
- **Shared, Bard-triggered:** the holds chain lives in shared role files — the TP rules apply to any job, and the singing/burst branches only activate when a Bard singer is present.

## Notes

- Song timing data comes from the game's real buff timers; the tracker was taught to survive their packet races (stale packets never delete fresh records, and records are never anchored down to a stale timer).
- Party chat mode does not affect any of this timing — chat runs on its own queue.
