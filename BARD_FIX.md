# Trust — Bard Fix

**Branch:** `brd-soul-voice-toggle` (fork of cyritegamestudios/trust) · **PR #577** · 129 commits · base: stock Trust v17.7.8

One package that turns stock Trust into a coordinated Bard farming machine. The whole fight loop — summon all five Trusts, sing the five-song burst at full potency, then pull — runs as one system: the singer, puller, attacker, debuffer and spammer all watch the same TP and singing state, so a weaponskill is never wasted, a burst never starts at the wrong moment, and no cast collides with another action's lock. Everything is scoped to attended play — it coordinates what the player is already doing; nothing runs unattended.

The per-fix record (what each bug was, how each fix was verified) lives in the commit history of PR #577. This bundle is that branch assembled: the complete addon, every fix already applied, one install.

## Install

1. Extract so the `trust` folder lands in `Windower\addons\` (back up your current `addons\trust` first).
2. In game: `//lua load trust`
3. Set CombatMode with the command, not the menu: `//trust set CombatMode Auto`
4. After the first install, run `//trust brd clear` once so the song tracker starts from a clean slate.

The matching GearSwap lives in its own repo, [Bard-Fix](https://github.com/Jojo1980247/Bard-Fix) — five songs need both halves: that repo's `data/BRD.lua` (install as `gearswap/data/BRD.lua`, then `//gs r`) equips Daurdabla for the dummy songs and the fifth-slot cast while this Trust sings the burst. A copy is also kept in this repo under `gearswap/BRD.lua`.

## The burst

Order: Honor March (Marcato, Marsyas), Victory March, Valor Minuet IV, the two Daurdabla dummies (Goblin Gavotte, Scop's Operetta), Valor Minuet V, Blade Madrigal (Gjallarhorn). Minuet V and Madrigal overwrite the dummies. The burst re-sings as a unit — when the first song comes due, all five refresh together on one clock.

Boosters, as one system:
- Soul Voice never fires alone — it always goes out with Nightingale + Troubadour (and Clarion Call when a fifth slot is open).
- A combo that comes off cooldown mid-burst waits and leads the next burst instead of firing into the current one.
- Marcato is paired with Nitro and never spent under Soul Voice (it does not stack — under Soul Voice its boost is capped and its duration bonus cancelled). Spent on plain bursts, its 10-minute recast desynced from Nitro's; now it fires on Honor March inside Nitro bursts only. The two Nitro combos without Soul Voice also come in a Marcato variant, ranked just above the plain combo: when Marcato is ready it goes out as the sequence's last step and rides Honor March; when it is on cooldown the plain combo fires instead, so Marcato can never block Nitro. (Before, Marcato's only path in a burst was the song it was attached to in the set — on the wrong song, or reached after the Nitro buffs faded, it just sat unused.)
- After the last combo ability lands, the first song waits out a 2-second grace so it never casts into the ability's tail ("Unable to cast at this time").

## Catching up a party member (Resing Missing Songs on Party Members)

A party member who missed part of the burst — out of range, or joined after it — no longer waits for the next re-sing. With the setting on (Trust menu, Song Sets), the singer checks each real player for a song they are missing and sings them that one song with Pianissimo, into their free slot, out of battle only, so a catch-up cast never takes the queue or swaps gear mid-fight. GearSwap's half of the rule: a Pianissimo patch is sung on Daurdabla, because the game checks the song limit against the instrument at landing — on the potency instrument the patch would overwrite the member's oldest song instead of adding the missing one.

The patch lands weaker than the burst's copy, so the singer follows up right away instead of waiting for the next burst: the same song again, Pianissimo on that one member only, this time on the potency instrument (GearSwap is armed for that one cast by a `//gs c potencyfollowup` command the singer sends first), refreshing their copy to full strength. Pianissimo's short recast lets it work song by song until the member is fully caught up, and nobody else's songs are ever touched.

Real players only. The game never sends a Trust's buffs (there is no 0x076 packet for Alter Egos), so a Trust's song records are reconstructed from the singer's own casts — and that reconstruction proved unreliable in game, firing Pianissimo in a Trust party whose songs were all up. A real player's buffs are reported by the game, so their records are real, and the feature acts on them.

The dedicated Pianissimo songs are separate from the catch-up: with AutoPianissimoMode on, Mage's Ballad III is sung with Pianissimo to each party member whose job is on the song's list (WHM and RDM — the mages), Trusts and real players alike. The gambits are rebuilt: instead of stock's max-songs count on the singer (which reads the same whether the cap is met by the set or by dummies), they require the set itself — every real song up on the singer — and hold while a burst is under way or a re-sing is due, so the Ballad goes out in the stable window right after a burst instead of being traded off the member by the re-sing's area casts. A Ballad is a standing buff, not a patch, so GearSwap keeps it on the potency instrument — the patch rule's Daurdabla would only shorten it.

Setup: Songs → your set → Pianissimo → Add Mage's Ballad III, then select it → Jobs → WHM and RDM (add PLD to cover a PLD tank Trust such as Amchuchu) → Confirm. The add creates the song with an empty job list — with no jobs selected it never fires, which is the most common reason Ballad looks broken. One Ballad only; adding a second can loop.

## The ordering rules (the holds chain)

- A banked weaponskill goes first: at 500+ TP, songs, debuffs, claims and new engages all wait; Nitro combos additionally require TP ≤ 999, so Nitro is never spent while a weaponskill is waiting.
- Once Nitro has gone off, that burst finishes first: the singer sings it through, and the weaponskill waits until the burst completes.
- The weaponskill is saved on a mob under 3% HP, held until the player reaches the fight's rolled combat distance, and never fired mid-song. All three are menu settings now (Trust menu → Combat → Config): **Save Weaponskill Under HP** (0–25%, default 3% — the right cutoff depends on the mob, since a stronger mob still has plenty of HP left at the same percent; 0% turns the save off), **Hold Weaponskill While Singing**, and **Hold Weaponskill For Distance** (both default on).
- Debuffs hold while singing, while a burst is pending, and for 2 seconds after a weaponskill lands; casts hold the same 2 seconds, so nothing collides with the weaponskill's action lock.
- The puller claims the mob in front of the player first; a mob behind is the second option — except a mob already aggroed on the party (a slept add keeps that status), which is never filtered out and is attacked next when the fought mob dies. Once claimed, the target sticks: a claim that drifts past pull range before it registers is held (out to a 50-yalm leash) instead of being dropped for an aggroed mob behind — it is released only when it dies, disengages after engaging, is claimed by another party, or is blacklisted.

## What is Bard, and what is every job

- **Bard:** the singer and burst, the song tracker's timer handling (including the two Marches, whose shared buff timers can no longer be paired to the wrong song), dummy songs, the Nitro system, the Marcato rules.
- **Every job:** front-first claiming and engage-claims, the weaponskill distance gate and save (menu-adjustable, see above), SpellAction waiting out the weaponskill lock for every spell, the 2-second wait after a spell's job abilities, casts not chasing the mob, the rolled combat distance and backpedal, the core audit (leaks, nil guards, queue protection), the menu background fix, the double raise-accept fix, debuffs remembered across a reload, and one Scholar strategem fix.
- **Shared, Bard-triggered:** the holds chain lives in shared role files — the TP rules apply to any job, and the singing/burst branches only activate when a Bard singer is present.

## Notes

- Song timing data comes from the game's real buff timers; the tracker was taught to survive their packet races (stale packets never delete fresh records, and records are never anchored down to a stale timer).
- Party chat mode does not affect any of this timing — chat runs on its own queue.
