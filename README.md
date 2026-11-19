# Brainrot Bog

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/fadlisick/roblox-brainrot-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/fadlisick/roblox-brainrot-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bog** is a 3D Roblox game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01): a neon swamp lagoon island at dusk where 48 original absurd brainrots walk a canal conveyor, players buy them onto their own coloured base, and money ticks in every second. Steal from unlocked bases, slap thieves with the Slap tool, lock your base, survive the tsunami that sweeps the map every 3 minutes, and rebirth for double income forever.

## The loop

- **Buy** — brainrots spawn on the central canal and walk east. Walk up, hit the BUY prompt, and your new brainrot walks to a free slot on your base.
- **Earn** — every brainrot pays its $/sec, ticked server-side once a second. Start at $100, climb from $5/s Commons to the $50,000/s Secret **The Infinite Loop**.
- **Steal** — pick a brainrot off another player's unlocked base and carry it home. The owner can slap you to make you drop it, and it walks back.
- **Lock** — buy a 60-second base lock so nobody can steal from you.
- **Survive** — every ~3 minutes a tsunami warning sounds, then a giant wave wall sweeps the island. Outside your base you are washed back to spawn and drop anything you carry.
- **Progress** — rebirth (10 brainrots + cash = income x2 each time, Index kept), buy extra base slots (up to 12), and level Walk Speed, Slap Power and Income Boost. Sell any brainrot for 50% back. The Index grid tracks all 48 characters: owned, seen, or ???.
- **Mutations** — brainrots can spawn Golden (x3), Diamond (x6), Rainbow (x12) or Void (x25).

## The cast (48, all original)

Six rarities x eight characters: Common (Sir Waddlesworth III, Toaster King, Captain Pickle, Banana Wizard, Sock Puppet Supreme, Grandma's Slipper, Sir Hootsworth, The Dancing Cactus), Rare (DJ Toilet, Shark in a Suit, Professor Egg, The Forbidden Burrito, Sneaker Goblin, Lava Lamp Larry, Bubble Gum Bandit, Sir Stinks-a-Lot), Epic (Sir Barksalot, Count Spatula, Madame Croissant, General Noodle, The Left Sock, Doctor Washing Machine, The Midnight Librarian, Captain Obvious), Legendary (Queen of the Fridge Light, Lord Buckethead, The Infinite Pretzel, Baron von Baguette, Emperor Couch Cushion, The Mayor of Nonsense, The Bureaucrat of Doom, Duchess of the Deep Fryer), Mythic (Chrono Toaster Prime, The Unpaid Intern, Sir Reginald von Meme, The Wi-Fi Wizard, Grand Admiral Rubber Duck, The Last Slice, The Overthinker, Lord of the Lost Remote), Secret (The One True Brainrot, CEO of the Void, The Algorithm Itself, Grandma's Secret Recipe, The Final Boss of Naps, He Who Must Not Be Named (Dave), The Singularity (a sentient toaster), The Infinite Loop).

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio, publish it as a Public experience (see `PUBLISH.md` for the full step-by-step), then play it at the place in `PLAY.json`.

## Layout

- `src/shared/BrainrotCatalog.luau` — the 48 brainrots, rarities and mutations
- `src/shared/GameSettings.luau` — every price, timer and layout number
- `src/shared/FormatMoney.luau` — `$1.5K` money formatting
- `src/server/WorldBuilder.luau` — builds the 3D island, canal, 8 bases, trees, lamps, signs
- `src/server/BrainrotFactory.luau` — builds brainrot character models + big readable labels
- `src/server/PlayerDataService.luau` — single source of player state (money, owned, rebirth, upgrades)
- `src/server/ConveyorService.luau` — spawn, walk, buy and despawn on the canal
- `src/server/BaseService.luau` — claim base, slots, lock, place brainrots
- `src/server/IncomeService.luau` — the $/sec money tick + leaderboard board
- `src/server/StealService.luau` — steal, carry, slap, drop and return
- `src/server/WaveService.luau` — the tsunami event (and `triggerTsunamiForTour` for reviewers)
- `src/server/ShopService.luau` — buy/sell/upgrade/rebirth remotes
- `src/server/init.server.luau` — boots all services
- `src/client/Game.client.luau` — boots the client
- `src/client/InterfaceController.luau` — HUD, Shop, Index, lock timer, wave banner, toasts
- `src/client/WorldEffects.luau` — client wave shake and canal shimmer
- `main.ts` — hands the game in: copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `dossier.json` with `vendor/makefun-roblox.ts` (unchanged)

---

<sub>Entered on [make.fun](https://make.fun/?ref=etjmfhb5&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
