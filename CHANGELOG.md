# Changelog

## 1.2

- Added opt-in Midnight per-raid settings for The Voidspire (2912), The Dreamrift (2939), March on Quel'Danas (2913), Sporefall (1592), The Tidebound Grotto (2987), and The Venomous Abyss (3004), all disabled by default. Existing The War Within entries and defaults are unchanged.
- Raid data source: [BigWigs Loader.lua](https://github.com/BigWigsMods/BigWigs/blob/master/Loader.lua). No live game validation was performed.

## 1.1

- Refactored roll selection, settings registration, slash commands, and test isolation without changing addon behavior
- Expanded wow-ui-sim regression coverage to 27 tests across roll modes, raid gating, Settings, slash commands, event toggling, and loot-history suppression
- Verified the real Blizzard loot-history OnShow hook path against the corrected simulator behavior

## 1.0.0

Modernized fork of Hizuro's AutoRoll (GPLv3), rewritten for current retail.

- Raid-specific activation with per-expansion toggles (Shadowlands, Dragonflight, The War Within) using real instance IDs
- Configurable default roll mode with fallback (Need / Greed / Disenchant / Transmog / Pass / Do nothing)
- Option to hide the loot history window while in an enabled raid
- Settings integrated with the modern Blizzard Settings UI
- Debug mode toggle
- Removed legacy item-list, DataBroker, localization and library code
