# Changelog

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
