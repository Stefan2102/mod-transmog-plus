# mod-transmog

Slot-based transmogrification module for [AzerothCore](https://github.com/azerothcore/azerothcore-wotlk) based on [azerothcore/mod-transmog](https://github.com/azerothcore/mod-transmog). The main difference is that appearances are stored per `(player, equipment slot)` instead of per item GUID, so the look stays when you swap gear. Other players see the transmogged appearance through the standard visible-item update hooks.

Features:

- Slot-based transmog — appearances stay on the equipment slot when you swap gear.
- Account-wide collection — any appearance unlocked by one character is available to all characters on the account.
- Appearances unlock when you equip an item, not when it enters your inventory.
- Flat copper cost per transmog application, fully configurable.
- Option to hide individual armor slots (helm, shoulders, chest, etc.). Configurable as free or paid.

## Installation

1. Copy this folder into your AzerothCore `modules/` directory:

   ```
   azerothcore-wotlk/
   └── modules/
       └── mod-transmog/
   ```

2. Apply the SQL files:

   ```bash
   mysql -u acore -p acore_characters < data/sql/characters/mod_transmog_characters.sql
   mysql -u acore -p acore_world     < data/sql/world/mod_transmog_world.sql
   ```

3. Copy `conf/mod_transmog.conf.dist` to your server's modules config folder and remove `.dist`.

4. Rebuild AzerothCore. CMake auto-discovers the module.

5. After the server starts, spawn the NPC in-game:
   ```
   .npc add 190012
   ```

## Configuration

All prices, quality requirements, type restrictions, and requirement ignores are configurable in `mod_transmog.conf`. See the distributed config file for details.

## License

GNU Affero General Public License v3 — see `LICENSE`.
