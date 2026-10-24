# Monetization setup (all games)

Every game already has the code for these game passes and developer products. To turn them on:
1. Publish the place (File > Publish to Roblox).
2. Creator Dashboard > your experience > Monetization > **Passes**: create each pass below with its name, price,
   description and the icon from `monetization/icons/<Game>/`.
3. Monetization > **Developer Products**: create each product below the same way.
4. Copy each new ID into the game's `ReplicatedStorage.Shared.Config` ModuleScript (in Studio) where it says `= 0`
   (for example `VIP = 0` becomes `VIP = 123456789`), then publish again.

Until an ID is filled in, the shop button still works in Studio test mode so you can try every item.

## BrainrotBall  (`build/BrainrotBall.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 199 | Double coins from wins and kills | `DoubleCoins` | `monetization/icons/BrainrotBall/DoubleCoins.png` |
| Game Pass | VIP | 249 | +50% coins, VIP tag, gold trail | `VIP` | `monetization/icons/BrainrotBall/VIP.png` |
| Game Pass | Quick Dash | 99 | Dash cooldown 3s instead of 6s | `QuickDash` | `monetization/icons/BrainrotBall/QuickDash.png` |
| Game Pass | Lucky Crates | 199 | 2x chance for Epic+ swords | `LuckyCrates` | `monetization/icons/BrainrotBall/LuckyCrates.png` |
| Dev Product | 1,000 Coins | 49 | Open more sword crates | `CoinsSmall` | `monetization/icons/BrainrotBall/CoinsSmall.png` |
| Dev Product | 6,000 Coins | 249 | Best value coin pile | `CoinsLarge` | `monetization/icons/BrainrotBall/CoinsLarge.png` |
| Dev Product | Second Chance | 29 | Jump back into this round! | `Respawn` | `monetization/icons/BrainrotBall/Respawn.png` |

## HatchABrainrot  (`build/HatchABrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Auto Clicker | 149 | Clicks for you 6 times a second, even AFK | `AutoClick` | `monetization/icons/HatchABrainrot/AutoClick.png` |
| Game Pass | 2x Brainpower | 199 | Double Brainpower forever | `DoubleClicks` | `monetization/icons/HatchABrainrot/DoubleClicks.png` |
| Game Pass | Triple Hatch | 249 | Hatch 3 eggs at once | `TripleHatch` | `monetization/icons/HatchABrainrot/TripleHatch.png` |
| Game Pass | Lucky | 199 | 1.5x luck on every egg | `Lucky` | `monetization/icons/HatchABrainrot/Lucky.png` |
| Game Pass | +3 Equips | 149 | Equip 3 more pets | `MoreEquips` | `monetization/icons/HatchABrainrot/MoreEquips.png` |
| Game Pass | +100 Storage | 49 | Hold 100 more pets | `MoreStorage` | `monetization/icons/HatchABrainrot/MoreStorage.png` |
| Dev Product | Brain Snack | 25 | 15 minutes of clicking (min 1K) | `PowerSmall` | `monetization/icons/HatchABrainrot/PowerSmall.png` |
| Dev Product | Brain Feast | 149 | 3 hours of clicking (min 100K) | `PowerLarge` | `monetization/icons/HatchABrainrot/PowerLarge.png` |
| Dev Product | 2x Luck (30m) | 49 | Double your hatch luck for 30 minutes | `LuckBoost` | `monetization/icons/HatchABrainrot/LuckBoost.png` |
| Dev Product | 5x Luck (15m) | 149 | QUINTUPLE luck for 15 minutes | `SuperLuckBoost` | `monetization/icons/HatchABrainrot/SuperLuckBoost.png` |
| Dev Product | Secret Egg | 99 | Guaranteed Mythic or better pet! | `SecretEgg` | `monetization/icons/HatchABrainrot/SecretEgg.png` |

## BrainrotHotel  (`build/BrainrotHotel.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | VIP | 249 | VIP tag, +50% knobs, 1 free revive every run | `VIP` | `monetization/icons/BrainrotHotel/VIP.png` |
| Game Pass | 2x Knobs | 149 | Double knobs from drawers and runs | `DoubleKnobs` | `monetization/icons/BrainrotHotel/DoubleKnobs.png` |
| Game Pass | Sixth Sense | 199 | Get warned about Sahur 3 seconds earlier | `SixthSense` | `monetization/icons/BrainrotHotel/SixthSense.png` |
| Game Pass | Lantern | 99 | A warm light that follows you through dark rooms | `Lantern` | `monetization/icons/BrainrotHotel/Lantern.png` |
| Dev Product | Revive | 25 | Come back at the newest door | `Revive` | `monetization/icons/BrainrotHotel/Revive.png` |
| Dev Product | Knob Bag | 49 | +750 knobs | `Knobs` | `monetization/icons/BrainrotHotel/Knobs.png` |
| Dev Product | Skip 10 Rooms | 39 | Jump 10 doors ahead | `SkipRooms` | `monetization/icons/BrainrotHotel/SkipRooms.png` |
| Dev Product | Summon Sahur | 19 | Sahur rushes through RIGHT NOW. Troll your friends! | `SummonSahur` | `monetization/icons/BrainrotHotel/SummonSahur.png` |

## BrainrotLiftingSimulator  (`build/BrainrotLiftingSimulator.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Auto Lift | 199 | Lifts for you 5 times a second, even AFK | `AutoLift` | `monetization/icons/BrainrotLiftingSimulator/AutoLift.png` |
| Game Pass | 2x Strength | 249 | Double strength from every lift | `DoubleStrength` | `monetization/icons/BrainrotLiftingSimulator/DoubleStrength.png` |
| Game Pass | 2x Wins | 199 | Double wins from every boss | `DoubleWins` | `monetization/icons/BrainrotLiftingSimulator/DoubleWins.png` |
| Game Pass | VIP | 249 | +50% strength, VIP tag | `VIP` | `monetization/icons/BrainrotLiftingSimulator/VIP.png` |
| Dev Product | Steroid-Free Shake | 29 | 20 minutes of lifting instantly | `StrengthPack` | `monetization/icons/BrainrotLiftingSimulator/StrengthPack.png` |
| Dev Product | Trophy Crate | 49 | +wins equal to beating your best boss 5 times | `WinsPack` | `monetization/icons/BrainrotLiftingSimulator/WinsPack.png` |
| Dev Product | Mega Protein (15m) | 79 | 3x strength for 15 minutes | `Protein` | `monetization/icons/BrainrotLiftingSimulator/Protein.png` |

## EscapeTheBrainrotObby  (`build/EscapeTheBrainrotObby.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Speed Coil | 99 | Toggle super speed | `SpeedCoil` | `monetization/icons/EscapeTheBrainrotObby/SpeedCoil.png` |
| Game Pass | Gravity Coil | 99 | Toggle mega jumps | `GravityCoil` | `monetization/icons/EscapeTheBrainrotObby/GravityCoil.png` |
| Game Pass | VIP | 249 | Rainbow trail, VIP tag, +1 free skip every finish | `VIP` | `monetization/icons/EscapeTheBrainrotObby/VIP.png` |
| Game Pass | 2x Wins | 149 | Get 2 wins every time you finish | `DoubleWins` | `monetization/icons/EscapeTheBrainrotObby/DoubleWins.png` |
| Dev Product | Skip Stage | 15 | Skip the stage you're on | `SkipStage` | `monetization/icons/EscapeTheBrainrotObby/SkipStage.png` |
| Dev Product | Skip 5 Stages | 59 | Jump ahead 5 stages | `Skip5` | `monetization/icons/EscapeTheBrainrotObby/Skip5.png` |
| Dev Product | Skip to End | 399 | Teleport to the final stage | `SkipToEnd` | `monetization/icons/EscapeTheBrainrotObby/SkipToEnd.png` |

## BrainrotRNG  (`build/BrainrotRNG.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Auto Roll | 149 | Rolls for you nonstop, even AFK | `AutoRoll` | `monetization/icons/BrainrotRNG/AutoRoll.png` |
| Game Pass | Quick Roll | 199 | Roll twice as fast | `QuickRoll` | `monetization/icons/BrainrotRNG/QuickRoll.png` |
| Game Pass | Permanent Luck | 299 | +50% luck forever | `Lucky` | `monetization/icons/BrainrotRNG/Lucky.png` |
| Game Pass | VIP | 249 | +20% luck, VIP tag, rainbow name | `VIP` | `monetization/icons/BrainrotRNG/VIP.png` |
| Dev Product | Luck Potion | 29 | 2x luck for 10 minutes | `LuckPotion` | `monetization/icons/BrainrotRNG/LuckPotion.png` |
| Dev Product | Super Luck Potion | 99 | 5x luck for 10 minutes | `SuperPotion` | `monetization/icons/BrainrotRNG/SuperPotion.png` |
| Dev Product | Heavenly Potion | 149 | Your next roll has 200x luck! | `HeavenlyPotion` | `monetization/icons/BrainrotRNG/HeavenlyPotion.png` |
| Dev Product | 2x Server Luck | 99 | 2x luck for EVERYONE for 15 minutes | `ServerLuck` | `monetization/icons/BrainrotRNG/ServerLuck.png` |

## BrainrotSlapBattles  (`build/BrainrotSlapBattles.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Slaps | 199 | Earn double slaps from every hit and kill | `DoubleSlaps` | `monetization/icons/BrainrotSlapBattles/DoubleSlaps.png` |
| Game Pass | VIP | 249 | +50% slaps, VIP tag, gold glove trail | `VIP` | `monetization/icons/BrainrotSlapBattles/VIP.png` |
| Game Pass | Sigma Glove | 399 | Massive knockback + shockwave ability | `SigmaGlove` | `monetization/icons/BrainrotSlapBattles/SigmaGlove.png` |
| Game Pass | Bombardiro Glove | 249 | Every slap explodes and launches nearby players | `BombGlove` | `monetization/icons/BrainrotSlapBattles/BombGlove.png` |
| Dev Product | 500 Slaps | 29 | Unlock gloves faster | `SlapsSmall` | `monetization/icons/BrainrotSlapBattles/SlapsSmall.png` |
| Dev Product | 4,000 Slaps | 149 | Best value slap pile | `SlapsLarge` | `monetization/icons/BrainrotSlapBattles/SlapsLarge.png` |
| Dev Product | Anti-Slap Shield (2m) | 39 | Nobody can slap you for 2 minutes | `Shield` | `monetization/icons/BrainrotSlapBattles/Shield.png` |

## BrainrotTowerDefense  (`build/BrainrotTowerDefense.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Speed | 149 | Toggle 2x game speed in matches | `DoubleSpeed` | `monetization/icons/BrainrotTowerDefense/DoubleSpeed.png` |
| Game Pass | +1 Unit Slot | 199 | Equip 5 units instead of 4 | `ExtraSlot` | `monetization/icons/BrainrotTowerDefense/ExtraSlot.png` |
| Game Pass | Lucky Summons | 299 | 2x chance for Epic+ units | `LuckySummon` | `monetization/icons/BrainrotTowerDefense/LuckySummon.png` |
| Game Pass | VIP | 249 | +50% gems from matches, VIP tag | `VIP` | `monetization/icons/BrainrotTowerDefense/VIP.png` |
| Dev Product | 500 Gems | 49 | 10 summons worth of gems | `GemsSmall` | `monetization/icons/BrainrotTowerDefense/GemsSmall.png` |
| Dev Product | 2,500 Gems | 199 | Best value: 50 summons | `GemsLarge` | `monetization/icons/BrainrotTowerDefense/GemsLarge.png` |
| Dev Product | Revive Base | 39 | Base back to full HP, keep playing! | `ReviveBase` | `monetization/icons/BrainrotTowerDefense/ReviveBase.png` |
| Dev Product | Mythic Unit | 299 | A random Mythic unit, guaranteed | `StarterPack` | `monetization/icons/BrainrotTowerDefense/StarterPack.png` |

## BrainrotTycoon  (`build/BrainrotTycoon.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Double all tycoon income forever | `DoubleCash` | `monetization/icons/BrainrotTycoon/DoubleCash.png` |
| Game Pass | Auto Collect | 149 | Cash goes straight to you, no pad needed | `AutoCollect` | `monetization/icons/BrainrotTycoon/AutoCollect.png` |
| Game Pass | Fast Droppers | 249 | All droppers drop 2x as fast | `FastDroppers` | `monetization/icons/BrainrotTycoon/FastDroppers.png` |
| Game Pass | VIP | 299 | Exclusive Sigma VIP Dropper + VIP tag | `VIP` | `monetization/icons/BrainrotTycoon/VIP.png` |
| Dev Product | Cash Stack | 29 | 10 min of income (min $1K) | `CashSmall` | `monetization/icons/BrainrotTycoon/CashSmall.png` |
| Dev Product | Cash Truck | 149 | 2 hours of income (min $50K) | `CashLarge` | `monetization/icons/BrainrotTycoon/CashLarge.png` |
| Dev Product | Golden Hour | 79 | 5x cash for 15 minutes | `GoldenHour` | `monetization/icons/BrainrotTycoon/GoldenHour.png` |

## BrainrotCardClash  (`build/BrainrotCardClash.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | VIP | 249 | VIP tag, +50% gems, 5-card deck | `VIP` | `monetization/icons/BrainrotCardClash/VIP.png` |
| Game Pass | 2x Gems | 199 | Double gems from every battle and passive income | `DoubleGems` | `monetization/icons/BrainrotCardClash/DoubleGems.png` |
| Game Pass | Lucky Packs | 299 | 2x chance of rare cards and mutations | `LuckyPacks` | `monetization/icons/BrainrotCardClash/LuckyPacks.png` |
| Game Pass | Open x5 | 149 | Open 5 packs at once | `FastOpen` | `monetization/icons/BrainrotCardClash/FastOpen.png` |
| Dev Product | Gem Pouch | 29 | +500 gems (scales with your stage) | `Gems` | `monetization/icons/BrainrotCardClash/Gems.png` |
| Dev Product | Gem Chest | 149 | +4,000 gems (scales with your stage) | `GemsBig` | `monetization/icons/BrainrotCardClash/GemsBig.png` |
| Dev Product | Mega Pack | 99 | A guaranteed Mythic or better card! | `MegaPack` | `monetization/icons/BrainrotCardClash/MegaPack.png` |
| Dev Product | 2x Server Luck | 79 | Rarer packs for EVERYONE for 15 min | `ServerLuck` | `monetization/icons/BrainrotCardClash/ServerLuck.png` |

## BrainrotColorBlock  (`build/BrainrotColorBlock.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 149 | Double coins every round | `DoubleCoins` | `monetization/icons/BrainrotColorBlock/DoubleCoins.png` |
| Game Pass | VIP | 249 | VIP tag, +50% coins | `VIP` | `monetization/icons/BrainrotColorBlock/VIP.png` |
| Game Pass | Fast Shoes | 99 | Run 20% faster | `Speed` | `monetization/icons/BrainrotColorBlock/Speed.png` |
| Game Pass | Color Sense | 199 | Know the next colour 1 second early | `ColorSense` | `monetization/icons/BrainrotColorBlock/ColorSense.png` |
| Dev Product | Revive | 25 | Back onto the board right now | `Revive` | `monetization/icons/BrainrotColorBlock/Revive.png` |
| Dev Product | Coin Bag | 49 | +1,000 coins | `Coins` | `monetization/icons/BrainrotColorBlock/Coins.png` |
| Dev Product | Slow Mode | 39 | +2 seconds to find the colour, for everyone, this round | `ExtraTime` | `monetization/icons/BrainrotColorBlock/ExtraTime.png` |

## DigToTheBrainrotCore  (`build/DigToTheBrainrotCore.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 199 | Every ore sells for double | `DoubleCoins` | `monetization/icons/DigToTheBrainrotCore/DoubleCoins.png` |
| Game Pass | Mega Backpack | 149 | 3x backpack space | `BigBackpack` | `monetization/icons/DigToTheBrainrotCore/BigBackpack.png` |
| Game Pass | Sell Anywhere | 99 | Sell from the menu, even deep underground | `SellAnywhere` | `monetization/icons/DigToTheBrainrotCore/SellAnywhere.png` |
| Game Pass | Lucky Miner | 199 | 2x chance for rare ores and fossils | `Lucky` | `monetization/icons/DigToTheBrainrotCore/Lucky.png` |
| Dev Product | Dynamite x5 | 25 | Blow up a 3x3x3 area instantly | `Dynamite` | `monetization/icons/DigToTheBrainrotCore/Dynamite.png` |
| Dev Product | Treasure Chest | 49 | Coins worth 20 min of mining (min 2K) | `CoinPack` | `monetization/icons/DigToTheBrainrotCore/CoinPack.png` |
| Dev Product | Mega Drill (10m) | 79 | 5x mining power for 10 minutes | `MegaDrill` | `monetization/icons/DigToTheBrainrotCore/MegaDrill.png` |

## BrainrotDisasterSurvival  (`build/BrainrotDisasterSurvival.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 149 | Double coins for every survival | `DoubleCoins` | `monetization/icons/BrainrotDisasterSurvival/DoubleCoins.png` |
| Game Pass | VIP | 249 | VIP tag, +50% coins, gold trail | `VIP` | `monetization/icons/BrainrotDisasterSurvival/VIP.png` |
| Game Pass | Balloon | 199 | Super jump: float above floods and stampedes | `Balloon` | `monetization/icons/BrainrotDisasterSurvival/Balloon.png` |
| Game Pass | Medkit | 99 | Slowly heal during every disaster | `Medkit` | `monetization/icons/BrainrotDisasterSurvival/Medkit.png` |
| Dev Product | Revive | 25 | Jump back into the current disaster | `Revive` | `monetization/icons/BrainrotDisasterSurvival/Revive.png` |
| Dev Product | Pick Next Disaster | 39 | You choose what hits next round | `ChooseDisaster` | `monetization/icons/BrainrotDisasterSurvival/ChooseDisaster.png` |
| Dev Product | Coin Bag | 49 | +1,500 coins | `Coins` | `monetization/icons/BrainrotDisasterSurvival/Coins.png` |

## EatTheBrainrotWorld  (`build/EatTheBrainrotWorld.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Size | 199 | Grow twice as fast from everything you eat | `DoubleSize` | `monetization/icons/EatTheBrainrotWorld/DoubleSize.png` |
| Game Pass | VIP | 249 | VIP tag, +50% size and coins | `VIP` | `monetization/icons/EatTheBrainrotWorld/VIP.png` |
| Game Pass | Auto Eat | 299 | Eat automatically, no clicking needed | `AutoEat` | `monetization/icons/EatTheBrainrotWorld/AutoEat.png` |
| Game Pass | Mega Bite | 149 | Eat 3x as many chunks per bite | `MegaBite` | `monetization/icons/EatTheBrainrotWorld/MegaBite.png` |
| Dev Product | Growth Snack | 29 | +25% size instantly (min +200) | `Size1` | `monetization/icons/EatTheBrainrotWorld/Size1.png` |
| Dev Product | Giant Feast | 149 | +150% size instantly (min +2,000) | `Size2` | `monetization/icons/EatTheBrainrotWorld/Size2.png` |
| Dev Product | Shrink Ray | 49 | Shrinks the BIGGEST other player by half! | `ShrinkRay` | `monetization/icons/EatTheBrainrotWorld/ShrinkRay.png` |
| Dev Product | Coin Bag | 49 | +2,000 coins (scales with rebirths) | `Coins` | `monetization/icons/EatTheBrainrotWorld/Coins.png` |

## FindTheBrainrots  (`build/FindTheBrainrots.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Brainrot Radar | 199 | A beam always points to the nearest brainrot you haven't found | `Radar` | `monetization/icons/FindTheBrainrots/Radar.png` |
| Game Pass | Teleporter | 99 | Teleport to any zone instantly | `Teleporter` | `monetization/icons/FindTheBrainrots/Teleporter.png` |
| Game Pass | Speed Coil | 79 | Run 75% faster | `SpeedCoil` | `monetization/icons/FindTheBrainrots/SpeedCoil.png` |
| Game Pass | Gravity Coil | 79 | Jump way higher | `GravityCoil` | `monetization/icons/FindTheBrainrots/GravityCoil.png` |
| Dev Product | Show Me One | 15 | A beam leads you to an unfound brainrot for 60s | `Hint` | `monetization/icons/FindTheBrainrots/Hint.png` |
| Dev Product | Instant Find | 49 | Instantly collect a random brainrot you're missing | `AutoFind` | `monetization/icons/FindTheBrainrots/AutoFind.png` |

## FishABrainrot  (`build/FishABrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Auto Fish | 299 | Catches fish automatically (AFK friendly) | `AutoFish` | `monetization/icons/FishABrainrot/AutoFish.png` |
| Game Pass | 2x Sell | 199 | Every fish sells for double | `DoubleSell` | `monetization/icons/FishABrainrot/DoubleSell.png` |
| Game Pass | Lucky Fisher | 199 | +50% luck forever | `Lucky` | `monetization/icons/FishABrainrot/Lucky.png` |
| Game Pass | Sell Anywhere | 99 | Sell fish from the menu | `SellAnywhere` | `monetization/icons/FishABrainrot/SellAnywhere.png` |
| Dev Product | Luck Totem | 79 | 3x luck for the WHOLE server for 10 min | `LuckTotem` | `monetization/icons/FishABrainrot/LuckTotem.png` |
| Dev Product | Mega Bait x20 | 49 | Next 20 casts: 3x luck + instant bites | `BigBait` | `monetization/icons/FishABrainrot/BigBait.png` |
| Dev Product | Treasure Chest | 49 | Cash worth 30 min of fishing (min $5K) | `CashPack` | `monetization/icons/FishABrainrot/CashPack.png` |
| Dev Product | Sigma Rod | 399 | The best rod in the game, instantly | `SigmaRod` | `monetization/icons/FishABrainrot/SigmaRod.png` |

## GrowABrainrot  (`build/GrowABrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Sell | 249 | Every fruit sells for double | `DoubleSell` | `monetization/icons/GrowABrainrot/DoubleSell.png` |
| Game Pass | Sell Anywhere | 99 | Sell from the menu, no walking | `SellAnywhere` | `monetization/icons/GrowABrainrot/SellAnywhere.png` |
| Game Pass | +12 Garden Spots | 199 | Plant 12 more seeds at once | `MoreSpots` | `monetization/icons/GrowABrainrot/MoreSpots.png` |
| Game Pass | Fast Grow | 149 | Plants grow 1.5x faster | `FastGrow` | `monetization/icons/GrowABrainrot/FastGrow.png` |
| Game Pass | Lucky Harvest | 199 | 2x mutation chance | `LuckyHarvest` | `monetization/icons/GrowABrainrot/LuckyHarvest.png` |
| Dev Product | Restock Shop | 29 | Instantly restock seeds for the WHOLE server | `Restock` | `monetization/icons/GrowABrainrot/Restock.png` |
| Dev Product | Grow All | 49 | Finish growing every plant in your garden | `GrowAll` | `monetization/icons/GrowABrainrot/GrowAll.png` |
| Dev Product | Mythic Seed Pack | 99 | A random Mythic or Secret seed | `MythicSeed` | `monetization/icons/GrowABrainrot/MythicSeed.png` |
| Dev Product | Summon Storm | 79 | Start a Brainrot Storm (huge mutations) for everyone | `Weather` | `monetization/icons/GrowABrainrot/Weather.png` |
| Dev Product | Cash Crate | 49 | Cash worth 30 min of farming (min $10K) | `CashPack` | `monetization/icons/GrowABrainrot/CashPack.png` |

## GuessTheBrainrot  (`build/GuessTheBrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 99 | Double coins for every right answer | `DoubleCoins` | `monetization/icons/GuessTheBrainrot/DoubleCoins.png` |
| Game Pass | VIP | 199 | VIP tag, +50% coins | `VIP` | `monetization/icons/GuessTheBrainrot/VIP.png` |
| Game Pass | Extra Time | 99 | +5 seconds on every question | `ExtraTime` | `monetization/icons/GuessTheBrainrot/ExtraTime.png` |
| Game Pass | Auto Hint | 249 | One wrong answer is removed on every question | `AutoHint` | `monetization/icons/GuessTheBrainrot/AutoHint.png` |
| Dev Product | 50/50 Hint | 9 | Removes two wrong answers | `Hint` | `monetization/icons/GuessTheBrainrot/Hint.png` |
| Dev Product | Skip | 15 | Skip this one and keep your streak | `Skip` | `monetization/icons/GuessTheBrainrot/Skip.png` |
| Dev Product | Coin Bag | 49 | +1,000 coins | `Coins` | `monetization/icons/GuessTheBrainrot/Coins.png` |

## BrainrotHideAndSeek  (`build/BrainrotHideAndSeek.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 149 | Double coins every round | `DoubleCoins` | `monetization/icons/BrainrotHideAndSeek/DoubleCoins.png` |
| Game Pass | VIP | 249 | VIP tag, +50% coins | `VIP` | `monetization/icons/BrainrotHideAndSeek/VIP.png` |
| Game Pass | Fast Shoes | 149 | Run 15% faster as hider or seeker | `Speed` | `monetization/icons/BrainrotHideAndSeek/Speed.png` |
| Game Pass | Seeker Pass | 99 | 3x more likely to be the seeker | `SeekerChance` | `monetization/icons/BrainrotHideAndSeek/SeekerChance.png` |
| Dev Product | Be the Seeker | 29 | You're the seeker next round | `BeSeeker` | `monetization/icons/BrainrotHideAndSeek/BeSeeker.png` |
| Dev Product | Radar Ping | 19 | Seeker: reveal every hider for 5 seconds | `Radar` | `monetization/icons/BrainrotHideAndSeek/Radar.png` |
| Dev Product | Coin Bag | 49 | +1,000 coins | `Coins` | `monetization/icons/BrainrotHideAndSeek/Coins.png` |

## BrainrotJumpRope  (`build/BrainrotJumpRope.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 149 | Double coins for every jump | `DoubleCoins` | `monetization/icons/BrainrotJumpRope/DoubleCoins.png` |
| Game Pass | VIP | 249 | VIP tag, +50% coins | `VIP` | `monetization/icons/BrainrotJumpRope/VIP.png` |
| Game Pass | Super Jump | 149 | Jump higher and hang in the air longer | `SuperJump` | `monetization/icons/BrainrotJumpRope/SuperJump.png` |
| Game Pass | Rope Shield | 199 | Survive one rope hit every round | `Shield` | `monetization/icons/BrainrotJumpRope/Shield.png` |
| Dev Product | Revive | 25 | Jump back in | `Revive` | `monetization/icons/BrainrotJumpRope/Revive.png` |
| Dev Product | Coin Bag | 49 | +1,000 coins | `Coins` | `monetization/icons/BrainrotJumpRope/Coins.png` |
| Dev Product | TURBO ROPE | 29 | Make the rope spin way faster. Chaos! | `SpeedUp` | `monetization/icons/BrainrotJumpRope/SpeedUp.png` |

## EscapeLavaForBrainrots  (`build/EscapeLavaForBrainrots.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Double ALL cash forever! | `DoubleCash` | `monetization/icons/EscapeLavaForBrainrots/DoubleCash.png` |
| Game Pass | VIP | 299 | 1.5x cash, VIP tag, gold trail | `VIP` | `monetization/icons/EscapeLavaForBrainrots/VIP.png` |
| Game Pass | Big Backpack | 249 | Carry 3 brainrots at once | `CarryMore` | `monetization/icons/EscapeLavaForBrainrots/CarryMore.png` |
| Game Pass | Speed Coil | 149 | Run 30% faster. Outrun the wave! | `SpeedCoil` | `monetization/icons/EscapeLavaForBrainrots/SpeedCoil.png` |
| Dev Product | Cash Pack | 29 | 10 minutes of income (min $5K) | `CashPack` | `monetization/icons/EscapeLavaForBrainrots/CashPack.png` |
| Dev Product | Cash Vault | 199 | 3 hours of income (min $250K) | `CashVault` | `monetization/icons/EscapeLavaForBrainrots/CashVault.png` |
| Dev Product | 2x Server Luck | 79 | Rarer brainrots for EVERYONE for 15 min | `ServerLuck` | `monetization/icons/EscapeLavaForBrainrots/ServerLuck.png` |
| Dev Product | Stop the Lava | 99 | No waves for 5 minutes, for the whole server | `StopLava` | `monetization/icons/EscapeLavaForBrainrots/StopLava.png` |
| Dev Product | Summon Secret | 149 | A SECRET brainrot spawns at the far end! | `SummonSecret` | `monetization/icons/EscapeLavaForBrainrots/SummonSecret.png` |

## MergeBrainrots  (`build/MergeBrainrots.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Double all income forever | `DoubleCash` | `monetization/icons/MergeBrainrots/DoubleCash.png` |
| Game Pass | Auto Merge | 249 | Merges matching brainrots for you | `AutoMerge` | `monetization/icons/MergeBrainrots/AutoMerge.png` |
| Game Pass | +10 Slots | 149 | A bigger board for more brainrots | `MoreSlots` | `monetization/icons/MergeBrainrots/MoreSlots.png` |
| Game Pass | Fast Drops | 149 | Free brainrots drop 2x as often | `FastDrops` | `monetization/icons/MergeBrainrots/FastDrops.png` |
| Dev Product | Cash Pile | 29 | 1 hour of income instantly | `CashPack` | `monetization/icons/MergeBrainrots/CashPack.png` |
| Dev Product | Level Up All | 99 | Every brainrot on your board +1 level | `LevelUp` | `monetization/icons/MergeBrainrots/LevelUp.png` |
| Dev Product | Mega Drop | 49 | Drops a brainrot 3 levels above your best buy | `MegaDrop` | `monetization/icons/MergeBrainrots/MegaDrop.png` |

## 99NightsWithSahur  (`build/99NightsWithSahur.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | VIP | 249 | VIP tag, +25% diamonds, start every run with 3 wood | `VIP` | `monetization/icons/99NightsWithSahur/VIP.png` |
| Game Pass | Big Bag | 149 | Carry 12 wood instead of 5 | `BigBag` | `monetization/icons/99NightsWithSahur/BigBag.png` |
| Game Pass | 2x Diamonds | 199 | Double diamonds for every night survived | `DoubleDiamonds` | `monetization/icons/99NightsWithSahur/DoubleDiamonds.png` |
| Game Pass | Golden Axe | 299 | Chop trees instantly and get 2 wood each | `GoldenAxe` | `monetization/icons/99NightsWithSahur/GoldenAxe.png` |
| Dev Product | Revive | 25 | Come back to life at the campfire right now | `Revive` | `monetization/icons/99NightsWithSahur/Revive.png` |
| Dev Product | Diamond Pack | 49 | +60 diamonds | `Diamonds` | `monetization/icons/99NightsWithSahur/Diamonds.png` |
| Dev Product | Fill the Fire | 19 | Instantly refuel the campfire for everyone | `FuelFire` | `monetization/icons/99NightsWithSahur/FuelFire.png` |
| Dev Product | Banish Sahur | 49 | Sahur leaves for the rest of this night | `BanishSahur` | `monetization/icons/99NightsWithSahur/BanishSahur.png` |

## PetBreakers  (`build/PetBreakers.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Auto Farm | 299 | Pets break nearby things on their own | `AutoFarm` | `monetization/icons/PetBreakers/AutoFarm.png` |
| Game Pass | Triple Hatch | 249 | Hatch 3 eggs at once | `TripleHatch` | `monetization/icons/PetBreakers/TripleHatch.png` |
| Game Pass | +4 Pet Equips | 199 | Equip 4 more pets | `MoreEquips` | `monetization/icons/PetBreakers/MoreEquips.png` |
| Game Pass | 2x Coins | 249 | Double coins from everything | `DoubleCoins` | `monetization/icons/PetBreakers/DoubleCoins.png` |
| Game Pass | Lucky Eggs | 199 | 2x chance for Golden, Rainbow and HUGE pets | `Lucky` | `monetization/icons/PetBreakers/Lucky.png` |
| Dev Product | Exclusive Egg | 99 | Dragon or Unicorn, 1 in 50 chance of HUGE | `ExclusiveEgg` | `monetization/icons/PetBreakers/ExclusiveEgg.png` |
| Dev Product | Server Luck (15m) | 79 | 2x egg luck for EVERYONE | `ServerLuck` | `monetization/icons/PetBreakers/ServerLuck.png` |
| Dev Product | Server 2x Coins (15m) | 79 | 2x coins for EVERYONE | `ServerCoins` | `monetization/icons/PetBreakers/ServerCoins.png` |
| Dev Product | Coin Bag | 29 | Coins worth 20 min of farming | `CoinsSmall` | `monetization/icons/PetBreakers/CoinsSmall.png` |
| Dev Product | Coin Vault | 149 | Coins worth 3 hours of farming | `CoinsLarge` | `monetization/icons/PetBreakers/CoinsLarge.png` |

## PizzaRestaurantTycoon  (`build/PizzaRestaurantTycoon.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Every order pays double | `DoubleCash` | `monetization/icons/PizzaRestaurantTycoon/DoubleCash.png` |
| Game Pass | Robot Waiter | 249 | Finished pizzas are served automatically | `AutoServe` | `monetization/icons/PizzaRestaurantTycoon/AutoServe.png` |
| Game Pass | Turbo Ovens | 199 | Every oven bakes 2x faster | `FastOvens` | `monetization/icons/PizzaRestaurantTycoon/FastOvens.png` |
| Game Pass | VIP | 249 | +50% tips, golden sign, VIP tag | `VIP` | `monetization/icons/PizzaRestaurantTycoon/VIP.png` |
| Dev Product | Rush Hour (10m) | 49 | Customers arrive 3x faster | `RushHour` | `monetization/icons/PizzaRestaurantTycoon/RushHour.png` |
| Dev Product | Celebrity Visit | 79 | A celebrity orders and tips 50x | `Celebrity` | `monetization/icons/PizzaRestaurantTycoon/Celebrity.png` |
| Dev Product | Cash Register | 49 | Cash worth 30 min of business | `CashPack` | `monetization/icons/PizzaRestaurantTycoon/CashPack.png` |

## SahurMystery  (`build/SahurMystery.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Coins | 199 | Double coins from every round | `DoubleCoins` | `monetization/icons/SahurMystery/DoubleCoins.png` |
| Game Pass | VIP | 249 | +50% coins, VIP tag, bigger coin bag (60) | `VIP` | `monetization/icons/SahurMystery/VIP.png` |
| Game Pass | Coin Magnet | 149 | Coins near you fly into your bag | `CoinMagnet` | `monetization/icons/SahurMystery/CoinMagnet.png` |
| Dev Product | Be Sahur Next | 49 | Hugely boosts your chance to be Tung Tung Sahur next round | `SahurPerk` | `monetization/icons/SahurMystery/SahurPerk.png` |
| Dev Product | Be Sheriff Next | 39 | Hugely boosts your chance to be Sheriff next round | `SheriffPerk` | `monetization/icons/SahurMystery/SheriffPerk.png` |
| Dev Product | 1,000 Coins | 49 | Open more weapon crates | `CoinPack` | `monetization/icons/SahurMystery/CoinPack.png` |

## SpeedBrainrotRace  (`build/SpeedBrainrotRace.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Speed | 199 | Gain speed twice as fast, forever | `DoubleSpeed` | `monetization/icons/SpeedBrainrotRace/DoubleSpeed.png` |
| Game Pass | 2x Wins | 149 | Double wins from every finish line | `DoubleWins` | `monetization/icons/SpeedBrainrotRace/DoubleWins.png` |
| Game Pass | VIP | 249 | VIP tag, rainbow trail, +50% speed gain | `VIP` | `monetization/icons/SpeedBrainrotRace/VIP.png` |
| Game Pass | Super Legs | 399 | 3x speed gain (stacks with 2x Speed!) | `SuperLegs` | `monetization/icons/SpeedBrainrotRace/SuperLegs.png` |
| Dev Product | +1,000 Speed | 29 | Instantly +1,000 speed | `Speed1K` | `monetization/icons/SpeedBrainrotRace/Speed1K.png` |
| Dev Product | +25,000 Speed | 199 | Instantly +25,000 speed | `Speed25K` | `monetization/icons/SpeedBrainrotRace/Speed25K.png` |
| Dev Product | Skip Zone | 19 | Teleport to the next finish line | `SkipZone` | `monetization/icons/SpeedBrainrotRace/SkipZone.png` |
| Dev Product | 3x Server Speed | 99 | 3x speed gain for EVERYONE for 10 minutes | `ServerBoost` | `monetization/icons/SpeedBrainrotRace/ServerBoost.png` |

## SquidChallenge  (`build/SquidChallenge.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Fast Shoes | 149 | Run 20% faster | `Speed` | `monetization/icons/SquidChallenge/Speed.png` |
| Game Pass | 2x Coins | 149 | Double coins from every round | `DoubleWins` | `monetization/icons/SquidChallenge/DoubleWins.png` |
| Game Pass | VIP | 249 | VIP tag, gold trail, +50% coins | `VIP` | `monetization/icons/SquidChallenge/VIP.png` |
| Game Pass | Glass Vision | 299 | Safe glass panels glow faintly for you | `GlassVision` | `monetization/icons/SquidChallenge/GlassVision.png` |
| Dev Product | Revive | 25 | Back into the current stage! | `Revive` | `monetization/icons/SquidChallenge/Revive.png` |
| Dev Product | Skip Stage | 49 | Jump straight to the next stage | `SkipStage` | `monetization/icons/SquidChallenge/SkipStage.png` |
| Dev Product | Coin Bag | 49 | +1,000 coins | `Coins` | `monetization/icons/SquidChallenge/Coins.png` |

## SurviveTungTungSahur  (`build/SurviveTungTungSahur.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Speedy Legs | 149 | Run 20% faster every round | `Speed` | `monetization/icons/SurviveTungTungSahur/Speed.png` |
| Game Pass | 2x Coins | 149 | Double coins from surviving | `DoubleCoins` | `monetization/icons/SurviveTungTungSahur/DoubleCoins.png` |
| Game Pass | VIP | 249 | +50% coins, VIP tag, gold trail | `VIP` | `monetization/icons/SurviveTungTungSahur/VIP.png` |
| Game Pass | Free Shield | 199 | Start every round with a shield | `StartShield` | `monetization/icons/SurviveTungTungSahur/StartShield.png` |
| Dev Product | Revive | 25 | Come back to life this round! | `Revive` | `monetization/icons/SurviveTungTungSahur/Revive.png` |
| Dev Product | Slow Sahur | 39 | Every Sahur moves at half speed for 15s | `SlowSahur` | `monetization/icons/SurviveTungTungSahur/SlowSahur.png` |
| Dev Product | Spawn Extra Sahur | 49 | Chaos! Another Sahur joins the hunt | `ExtraSahur` | `monetization/icons/SurviveTungTungSahur/ExtraSahur.png` |
| Dev Product | Coin Bag | 49 | +500 coins | `Coins` | `monetization/icons/SurviveTungTungSahur/Coins.png` |

## TowerOfBrainrot  (`build/TowerOfBrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | Speed Coil | 149 | Toggle super speed | `SpeedCoil` | `monetization/icons/TowerOfBrainrot/SpeedCoil.png` |
| Game Pass | Gravity Coil | 149 | Toggle mega jumps | `GravityCoil` | `monetization/icons/TowerOfBrainrot/GravityCoil.png` |
| Game Pass | VIP | 249 | VIP tag, rainbow trail, +50% coins | `VIP` | `monetization/icons/TowerOfBrainrot/VIP.png` |
| Game Pass | 2x Coins | 149 | Double coins for reaching the top | `DoubleCoins` | `monetization/icons/TowerOfBrainrot/DoubleCoins.png` |
| Dev Product | Rising Lava (mutator) | 49 | Lava slowly rises for EVERYONE this round | `LavaRise` | `monetization/icons/TowerOfBrainrot/LavaRise.png` |
| Dev Product | +2 Minutes | 29 | Adds 2 minutes to the round timer | `SlowTime` | `monetization/icons/TowerOfBrainrot/SlowTime.png` |
| Dev Product | Skip Section | 25 | Teleport up one section | `SkipSection` | `monetization/icons/TowerOfBrainrot/SkipSection.png` |
| Dev Product | New Tower Now | 79 | Rebuild the tower immediately | `NewTower` | `monetization/icons/TowerOfBrainrot/NewTower.png` |

## EscapeTsunamiForBrainrots  (`build/EscapeTsunamiForBrainrots.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Double ALL cash forever! | `DoubleCash` | `monetization/icons/EscapeTsunamiForBrainrots/DoubleCash.png` |
| Game Pass | VIP | 299 | 1.5x cash, VIP tag, gold trail | `VIP` | `monetization/icons/EscapeTsunamiForBrainrots/VIP.png` |
| Game Pass | Big Backpack | 249 | Carry 3 brainrots at once | `CarryMore` | `monetization/icons/EscapeTsunamiForBrainrots/CarryMore.png` |
| Game Pass | Speed Coil | 149 | Run 30% faster. Outrun the wave! | `SpeedCoil` | `monetization/icons/EscapeTsunamiForBrainrots/SpeedCoil.png` |
| Dev Product | Cash Pack | 29 | 10 minutes of income (min $5K) | `CashPack` | `monetization/icons/EscapeTsunamiForBrainrots/CashPack.png` |
| Dev Product | Cash Vault | 199 | 3 hours of income (min $250K) | `CashVault` | `monetization/icons/EscapeTsunamiForBrainrots/CashVault.png` |
| Dev Product | 2x Server Luck | 79 | Rarer brainrots for EVERYONE for 15 min | `ServerLuck` | `monetization/icons/EscapeTsunamiForBrainrots/ServerLuck.png` |
| Dev Product | Stop the Tsunami | 99 | No waves for 5 minutes, for the whole server | `StopTsunami` | `monetization/icons/EscapeTsunamiForBrainrots/StopTsunami.png` |
| Dev Product | Summon Secret | 149 | A SECRET brainrot spawns at the far end! | `SummonSecret` | `monetization/icons/EscapeTsunamiForBrainrots/SummonSecret.png` |

## YoinkABrainrot  (`build/YoinkABrainrot.rbxlx`)

| Type | Name | Price (R$) | Description | Config key | Icon |
|---|---|---|---|---|---|
| Game Pass | 2x Cash | 199 | Double ALL cash forever! | `DoubleCash` | `monetization/icons/YoinkABrainrot/DoubleCash.png` |
| Game Pass | VIP | 299 | 1.5x cash, 2x base lock time, VIP tag | `VIP` | `monetization/icons/YoinkABrainrot/VIP.png` |
| Game Pass | +5 Slots | 149 | Hold 5 more brainrots in your base | `ExtraSlots` | `monetization/icons/YoinkABrainrot/ExtraSlots.png` |
| Game Pass | Speed Coil | 99 | Run 40% faster. Steal & escape! | `SpeedCoil` | `monetization/icons/YoinkABrainrot/SpeedCoil.png` |
| Dev Product | Cash Pack | 25 | 10 minutes of your income (min $5K) | `CashSmall` | `monetization/icons/YoinkABrainrot/CashSmall.png` |
| Dev Product | Cash Bag | 99 | 1 hour of your income (min $50K) | `CashMedium` | `monetization/icons/YoinkABrainrot/CashMedium.png` |
| Dev Product | Cash Vault | 399 | 8 hours of your income (min $1M) | `CashLarge` | `monetization/icons/YoinkABrainrot/CashLarge.png` |
| Dev Product | 2x Server Luck | 79 | Doubles rare spawns for EVERYONE for 15 min | `ServerLuck` | `monetization/icons/YoinkABrainrot/ServerLuck.png` |
| Dev Product | Summon Secret | 149 | Spawns a SECRET brainrot. You get first dibs! | `SpawnSecret` | `monetization/icons/YoinkABrainrot/SpawnSecret.png` |
| Dev Product | Instant Lock | 19 | Lock your base right now, skipping cooldown | `InstantLock` | `monetization/icons/YoinkABrainrot/InstantLock.png` |
