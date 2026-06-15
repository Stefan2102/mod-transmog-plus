# mod-transmog

Slot-based transmogrification module for AzerothCore WotLK 3.3.5a.

**Author:** Stefan2102

Based on the official [azerothcore/mod-transmog](https://github.com/azerothcore/mod-transmog). The main difference is that appearances are stored per `(player, equipment slot)` instead of per item GUID, so the look stays when you equip a new item in the same slot. 

Features:

- Account-wide appearance collection — unlocked only when a character equips an armor or weapon item. Once unlocked, all characters on the same account can use the appearance.
- Gossip NPC similar to the official `mod-transmog`.
- Configurable flat copper cost.
- Hide armor slot option (configurable free or paid). Weapons, jewelry, and trinkets cannot be hidden.

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

5. Spawn the NPC in-game. The world SQL already places Warpweavers in Stormwind and Orgrimmar. To add one at your current location, use:
   ```
   .npc add 190012
   ```

## Configuration

All prices, quality requirements, type restrictions, and requirement ignores are configurable in `mod_transmog.conf`. See the distributed config file for details.

## License

GNU Affero General Public License v3 — see `LICENSE`.
