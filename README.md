#  Olympus Grand Casino
### A 10-floor boss-rush gun game built in UEFN with Verse

Fight your way up a Japanese casino tower, floor by floor, weapon by weapon — and on the rooftop helipad, take the Thunderbolt of Zeus into a duel against Hades himself.

I built this end-to-end: game design, the Verse systems that run it, the difficulty model, and the level itself. This README covers what the game does and, more importantly, how it works under the hood.

---

##  What it plays like

- **Climb 10 floors.** Floors 1–9 are sealed combat arenas. Floor 10 is the boss.
- **Gun-game rules.** Every floor hands you a fresh loadout — a gun and a blade — and wipes the old one. You master a weapon, then you lose it.
- **Pressure that scales.** Floor 1 sends 14 enemies at you, 4 at a time. Floor 9 sends 62, ten at a time, every kill instantly replaced. Half shoot, half charge you with katanas.
- **Death costs you, but doesn't erase you.** Die mid-climb and you respawn straight back into the floor you were fighting — healed, re-armed, quota intact.
- **The finale:** a 4500 HP melee Hades with bodyguards, against your Thunderbolt of Zeus. Kill him and the game ends, crediting whoever landed the final blow.

##  How it's built

Two Verse devices carry the whole experience:

**`casino_gungame_manager.verse` — the game brain.** A single async game loop that sequences all ten floors: it computes each floor's enemy budget and concurrency cap, drives spawn waves through an event-signal pattern (every elimination signals the loop, which decides whether to backfill), grants loadouts, teleports players by *coordinates* rather than teleporter devices, catches respawns and routes players back to the active floor, narrates progress through the HUD, and runs the boss encounter through to victory.

**`japanese_casino_tower.verse` — the architecture system.** A procedural pagoda generator: tapering tiers, tilted roof eaves, lantern rows, a torii entrance gate, interior cover scatter, and a lit helipad — all computed from a handful of dimension parameters. It doubles as the spatial anchor: the manager derives every floor's teleport coordinates from this device's transform, so the entire game re-anchors if you move one object.

### Engineering decisions I'm proud of

- **Difficulty lives in code, not in 18 hand-tuned devices.** Enemy totals, concurrency, and the gun/melee ratio are computed per floor from a few `@editable` dials. Rebalancing the whole game takes seconds in a Details panel, no recompile.
- **Working around platform limits instead of hitting walls.** Verse can't set guard HP (editor-only), can't spawn devices, and some spawner limits are locked in the UI. Solutions: a two-archetype spawner design that gets 9 floors of scaling from 2 configs, `Reset()`-before-`Spawn()` to make spawn caps irrelevant, and coordinate-based teleportation to eliminate 10 teleporter devices entirely.
- **Respawn recovery via event routing.** Player spawner events feed a handler that tracks the active floor index and restores dead players into the fight — turning what the platform gives you (respawn at a pad) into what the design needs (rejoin the run).
- **Sealed-arena progression.** No stairs by design: teleport-gated floors make sequence-breaking impossible and turn each floor into a tunable, self-contained encounter.

### Debugging in the real world

This wasn't written in one clean pass. Shipping it meant working through Verse's failure-typed expressions (integer division producing rationals, failable `=` comparisons being illegal inside `or`), version-drifted API names, runtime-spawned geometry breaking AI navigation (which drove the pivot to static level geometry + code-driven gameplay), and asset-type mismatches between gallery pieces and spawnable props. Every one of those is a fix you can read in the commit history.

## ⚙️ Tuning surface

| Dial | Default | What it changes |
|------|---------|-----------------|
| `BaseEnemiesPerFloor` | 14 | Floor 1 kill quota |
| `EnemiesAddedPerFloor` | 6 | Quota growth per floor |
| `BaseSimultaneousEnemies` | 4 | Concurrent enemies on floor 1 (caps at 10) |
| `MeleeGuardPercent` | 50 | Katana-to-gun guard ratio |
| `IntermissionSeconds` | 8 | Breather between floors |

##  Running it yourself

1. Two Verse device files (names matching the sources), paste, **Build Verse Code**.
2. A 10-story tower (hand-built or generated) — note story height and footprint.
3. Per combat floor: one gun-guard spawner, one melee-guard spawner. Ten item granters (floor 10's holds the Thunderbolt). An NPC-definition Hades + spawner on the roof.
4. Drop in the tower device (floor 1 center) and the manager, wire the `@editable` arrays in floor order, link every player spawn pad.
5. Island settings: 1 round, no default win conditions, infinite respawns. Launch.

##  Skills demonstrated

Gameplay systems design · Verse (functional-logic language, async concurrency, failure typing) · event-driven architecture · procedural generation · difficulty modeling · working within and around platform API constraints · level design · iterative playtest-driven debugging

---

please email me for the map code on fortnite 
