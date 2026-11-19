# PUBLISH.md — How to publish Brainrot Bog (user steps, Windows/Mac + Roblox Studio)

**Your play code is: `makefun-coin-croquet-pinto`** (code 0 of 4 for this account in roblox-brainrot-01; any one of the 4 passes — fetch another with `node cli/makefun.mjs check --repo <repo> --play-code 1` from inside the kit if Roblox refuses this one). It must appear exactly, as it stands, in the experience's description.

**Deadline: 20 Nov 2026, 21:30 WIB (2026-11-20T14:30Z).** Do the publish-first steps now — if Studio/Roblox refuses any step, STOP and tell us.

## 1. Open the place in Roblox Studio

- On your Windows/Mac, open Roblox Studio and sign in to the Roblox account (must be at least 2 days old and past Roblox's one-time age check — facial age estimation or government ID — or it cannot publish publicly).
- File → Open, and open `game.rbxl` from this repo.

## 2. Publish it as a new experience and set it Public

- File → **Publish to Roblox As…** → **New experience**, name it **"Brainrot Bog"**.
- Then on the Creator Dashboard (https://create.roblox.com/dashboard/creations): open the experience → description — write this description (it MUST include the play code exactly, plus a plain description; Roblox refuses text that reads as a web address, so never write make.fun with its dot):

  > Brainrot Bog — a neon swamp lagoon where 48 original brainrots walk the canal. Buy them, grow your base, steal, slap, survive the tsunami, rebirth for double income. Play code: makefun-coin-croquet-pinto

- Set the genre, answer the content questions (answer **No** to age-restricted content if asked, or complete the questionnaire), and set the experience **Public** (Publish settings → Manage Audience → Manage access → Public tab).
- **This is the publish-first check — if Studio/Roblox refuses any step, STOP and tell us.**

## 3. Play-test in Studio (Play button)

- Press Play in Studio. Walk around, buy a brainrot at the conveyor (BUY prompt), watch money tick up in the top bar, open SHOP and INDEX, buy a base lock, and if you have a second account, test stealing and slapping.
- To test the tsunami now instead of waiting ~3 minutes, in Studio's Command Bar (Server) run: `require(game.ServerScriptService.Server.WaveService).triggerTsunamiForTour("tour")`
- Fix anything broken and tell us (we rebuild `game.rbxl`; you re-open it).

## 4. Take 3–4 screenshots WHILE the game is running (16:9, 1280x720)

1. **1-thumbnail.jpg** (THUMBNAIL/cover) — wide shot of the island, canal with brainrots walking, a base, HUD visible.
2. **2-buy.jpg** — buying a brainrot at the conveyor (BUY prompt open).
3. **3-base.jpg** — a base full of brainrots with money ticking in the top bar.
4. **4-wave.jpg** — the tsunami wave sweeping the map (use the command in step 3).

Keep HUD text clear of the top-left corner (Roblox menu buttons sit there). Save each file **≤256 KiB** (re-encode/scale down if bigger), name them exactly `1-thumbnail.jpg`, `2-buy.jpg`, `3-base.jpg`, `4-wave.jpg`, and put them in the repo's `screenshots/` folder (it is empty now — you replace nothing).

## 5. Upload the icon and thumbnails on the Creator Dashboard

- Creator Dashboard → Creations → the experience → Configurations → Places → start place (marked with a star) → **Icon**: upload a square picture 512x512 of the game (compose from the world/characters).
- **Thumbnails** (Experience Detail Page tab): upload `1-thumbnail.jpg` FIRST.
- Wait until the experience page shows both past review (Roblox reviews uploads; **do NOT submit while either is missing/in review** — the link is refused).

## 6. Fill in PLAY.json and send it back to us

- In Studio: File → Game Settings → Basic Info, or Creator Dashboard → Configure — confirm the description still holds the play code.
- Get the ids: `place_id` = the number in the play link (`https://www.roblox.com/games/<placeId>`), `universe_id` = the number after `experiences/` in the Dashboard URL (or `game.GameId` in Studio; `game.PlaceId` is the place).
- Put them in the repo's `PLAY.json` as:

  ```json
  {"url": "https://www.roblox.com/games/<placeId>", "place_id": <placeId>, "universe_id": <universeId>}
  ```

- Send the filled `PLAY.json` + the 4 screenshots back to us so we put them in the repo and commit **WHILE the recording still runs**, then the parent seals and submits.

## 7. GitHub repo About

- Set the repo About if not done: website https://make.fun/bounty/roblox-brainrot-01 (we try `gh repo edit` from here; if it fails, do it on GitHub: repo page → About gear → Website field).

## If the play code is refused

If Roblox refuses the description with `makefun-coin-croquet-pinto`, fetch another code: from inside the unpacked kit run `node cli/makefun.mjs check --repo <repo> --play-code 1` (then 2, then 3). Any one of the 4 passes — use the new one in the description instead and tell us which.
