# Brainrot Game Factory

Ready-to-publish Roblox games in the styles that currently earn the most (Steal a Brainrot, Grow a Garden,
pet simulators, obbies). Every game builds its whole map, UI and characters from code, so you can open a
file in Roblox Studio, hit Play, and it works. No models or assets are needed.

| Game | Based on | Place file |
|------|----------|------------|
| **Yoink a Brainrot** | Steal a Brainrot | `build/YoinkABrainrot.rbxlx` |
| **Hatch a Brainrot** | Pet / clicker simulators | `build/HatchABrainrot.rbxlx` |
| **Escape the Brainrot Obby** | Skip-stage obbies | `build/EscapeTheBrainrotObby.rbxlx` |
| **Grow a Brainrot** | Grow a Garden | `build/GrowABrainrot.rbxlx` |
| **Brainrot Tycoon** | Classic dropper tycoons | `build/BrainrotTycoon.rbxlx` |
| **Survive Tung Tung Sahur** | Round-based chase/survival | `build/SurviveTungTungSahur.rbxlx` |
| **Brainrot RNG** | Sol's RNG (aura rolling) | `build/BrainrotRNG.rbxlx` |
| **Fish a Brainrot** | Fisch (fishing + reel minigame) | `build/FishABrainrot.rbxlx` |
| **Brainrot Tower Defense** | Toilet Tower Defense (co-op waves + unit gacha) | `build/BrainrotTowerDefense.rbxlx` |
| **Brainrot Ball** | Blade Ball (parry PvP + sword crates) | `build/BrainrotBall.rbxlx` |
| **Merge Brainrots** | Idle merge games (mobile-friendly UI) | `build/MergeBrainrots.rbxlx` |
| **Find the Brainrots** | Find-the-X collection games (hints/radar) | `build/FindTheBrainrots.rbxlx` |
| **Brainrot Lifting Simulator** | Arm Wrestle Simulator (lift + boss arm-wrestling) | `build/BrainrotLiftingSimulator.rbxlx` |
| **Dig to the Brainrot Core** | Mining simulators (dig, ores, brainrot fossils) | `build/DigToTheBrainrotCore.rbxlx` |
| **Brainrot Slap Battles** | Slap Battles (PvP gloves, knock players off) | `build/BrainrotSlapBattles.rbxlx` |
| **Sahur Mystery** | Murder Mystery 2 (Sahur / Sheriff / Innocents, skin crates) | `build/SahurMystery.rbxlx` |
| **Tower of Brainrot** | Tower of Hell (random tower, timer, lava mutator) | `build/TowerOfBrainrot.rbxlx` |
| **Pet Breakers** | Pet Simulator 99 (pets break coins, areas, eggs, HUGE pets) | `build/PetBreakers.rbxlx` |
| **Pizza Restaurant Tycoon** | My Restaurant (customers, ovens, staff, upgrades) | `build/PizzaRestaurantTycoon.rbxlx` |
| **Squid Challenge** | Squid Game minigames (Red Light Green Light + Glass Bridge, revives) | `build/SquidChallenge.rbxlx` |
| **+1 Speed Brainrot Race** | "+1 Speed Every Second" games (huge track, wins, trails, rebirths) | `build/SpeedBrainrotRace.rbxlx` |
| **Escape the Tsunami for Brainrots** | Escape Tsunami for Brainrots (grab brainrots, outrun the wave, shelters, base income) | `build/EscapeTsunamiForBrainrots.rbxlx` |
| **99 Nights with Sahur** | 99 Nights in the Forest (campfire, wood, hunger, night monster, classes) | `build/99NightsWithSahur.rbxlx` |
| **Brainrot Disaster Survival** | Natural Disaster Survival (6 disasters, pick-the-next-disaster product, upgrades) | `build/BrainrotDisasterSurvival.rbxlx` |
| **Brainrot Card Clash** | Anime Card Clash (card packs, mutations, 3-card deck, boss ladder) | `build/BrainrotCardClash.rbxlx` |
| **Brainrot Hotel** | DOORS (100 rooms, drawers, closets, Sahur rush, troll Summon product) | `build/BrainrotHotel.rbxlx` |
| **Eat the Brainrot World** | Eat the World (eat the city to grow, eat smaller players, Shrink Ray) | `build/EatTheBrainrotWorld.rbxlx` |

More games are listed at the bottom as they get added.

## How to publish one and start earning

1. **Open it.** Double-click a `.rbxlx` from `build/` and it opens in Roblox Studio. Press **Play** to test.
   Shop buttons work in Studio even before you set up IDs. They grant the item instantly so you can test.
2. **Publish.** Go to File → Publish to Roblox. Then open Game Settings and do these three things:
   - Security → turn on **Enable Studio Access to API Services**, so saving works in Studio.
   - Places → set **Max Players**. Use 8 for Yoink a Brainrot (8 bases), and 6 for Grow a Brainrot and Brainrot Tycoon (6 plots each).
   - Basic Info: pick a genre, then add a good **icon and thumbnails**. Thumbnails matter more than anything else for clicks.
3. **Create the paid items.** In the Creator Dashboard, open your experience → Monetization:
   - **Passes:** make one for each entry in that game's `src/shared/Config.luau` → `Config.Passes`.
     Suggested prices are in `Config.PassInfo`.
   - **Developer Products:** make one for each entry in `Config.Products`. Prices are in `Config.ProductInfo`.
   - Paste each ID into `Config.luau`, replacing the `0`. Rebuild (see below) or edit the ModuleScript
     `ReplicatedStorage.Shared.Config` directly in Studio, then publish again.
4. **Make it public**, then run Roblox **Ads / Sponsored experiences** with a small budget to get the first players.
   The algorithm only recommends games that already have players.

### Which game to launch first
1. **Yoink a Brainrot** and **Grow a Brainrot** copy the two biggest earners on Roblox right now. Start with one of these.
2. **Survive Tung Tung Sahur** and **Brainrot Ball** are round-based and best with friends, which makes them good for TikTok/Shorts clips.
3. The obby is the cheapest to run and earns steadily from Skip Stage. It's a good second or third game.

Focus on one game at a time. Make an eye-catching icon (a big brainrot face plus bright text), run about 1,000 Robux of ads,
watch the Analytics tab for retention, and push small updates often: new brainrots, seeds or units are one line in `Config.luau`.

### Where the money comes from
- **Game passes:** one-time purchases (2x cash, VIP, auto clicker, extra slots and so on).
- **Developer products:** repeat purchases (cash packs, server luck, skip stage, restock, summon secret).
  These earn the most in all of these genres.
- **Premium Payouts:** Roblox pays you automatically for time Premium players spend in your game.
  Offline earnings, gifts, events and restocks are built in to keep players coming back.

Server-wide boosts (2x Server Luck, Restock Shop, Summon Storm, Summon Secret) are announced to everyone with the
buyer's name. That social proof is what makes these products sell in the real games.

## Safe-by-default systems (`shared/`)
- `shared/server/DataService.luau`: DataStore saving with session locking, so items can't be duplicated by
  server-hopping. It also autosaves, saves on shutdown, and kicks the player instead of overwriting their data
  when a load fails.
- `shared/server/MonetizationService.luau`: `ProcessReceipt` done properly. Each purchase is granted exactly
  once, and the save finishes before Roblox is told the purchase succeeded. It also handles pass ownership
  and the Studio test purchases.
- `shared/common/`: number formatting (1.2K, 3.4M…) and UI helpers.

## Tests
`tests/run.sh` runs the save system and purchase handling against mocked Roblox APIs under the plain `luau` CLI.
It covers receipts being granted exactly once, failed saves never being reported as granted, session locks
blocking duplicate loads, stale servers being unable to overwrite newer data, and shutdown saves.

`tests/smoke/run.sh path/to/API-Dump.json [game ...]` plays each game in an offline Roblox emulator. It joins as a
player, clicks every button, triggers every prompt, buys every pass and product, dies, respawns and leaves, then reports
any script error. Every property, event and enum is checked against Roblox's real API dump.

## Brainrot models
All characters come from `shared/common/BrainrotModels.luau`, which is generated by `tools/gen_brainrots.py` from
`tools/brainrot_specs.py`. Those specs describe each character part by part, using smooth ellipsoids, cylinders,
wedges and blocks. Edit the specs and re-run the generator to change a character.

## Editing / rebuilding
The games use [Rojo](https://rojo.space). To rebuild every place file:

```bash
scripts/build-all.sh            # needs `rojo` on PATH
```

For live-sync while editing in Studio, run `rojo serve games/<game>/default.project.json` and connect with the
Rojo Studio plugin.

Want real 3D models instead of the cartoon part-built ones? In Yoink a Brainrot, put a Model named after the
brainrot's `Id` (for example `tung`), with a PrimaryPart, inside `ServerStorage.Brainrots`. The game uses it automatically.

## Tuning tips
- All the numbers are in each game's `Config.luau`: prices, income, spawn rates, rarities and so on.
- Add new brainrots, pets, seeds or eggs by adding a line to the lists in `Config.luau`. Nothing else needs to change.
- Change the `DataService.Init("..._v1", ...)` store name **only** if you want to wipe everyone's data.
