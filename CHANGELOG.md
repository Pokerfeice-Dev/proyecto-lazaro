# Changelog

All notable changes and fixes for Project Lazaro (formerly Project Frankenstein).

## [1.2.0] - 2026-06-12

### Added
- **Hades-Style Physical Shop:**
  - Replaced the old UI-based ShopMenu with a physical, in-room shop layout inside Ygor's room.
  - **Hologram Pedestals:** Added script-driven holograms (`hologram_ygor_store.tscn`) that automatically spawn items on markers based on node names (Pedestal 1: Health, Pedestal 2: Random Body Item, Pedestal 3: Random Weapon Item, Pedestal 4: hides itself).
  - **Physical Shop Items:**
    - Levitating item icons that smoothly float up and down using a sine wave.
    - Displays the actual item icon (loaded dynamically) and cost/prompt label.
    - Pressing `E` detects player proximity, spends carne, triggers the purchase effect, plays a teleport sound, and removes the item.
    - **Health Purchase (Vida):** Costs 20 carne. Regenerates `25%` of the player's *missing health* (calculated as `max_health - current_health`). Uses the new custom pixel art icon at `Art/Items/Player/Heart/Heart.png`.
    - **Random Body Item:** Costs 30 carne. Grants a random defensive item.
    - **Random Weapon Item:** Costs 40 carne. Grants a random offensive item.
- **NPC Dialogue System:**
  - Configured Ygor (`ygor.gd`) to show random floating dialogue lines (e.g. *"La carne es la única moneda aquí."*) on interaction instead of opening the UI window.
- **Player Death Sound:**
  - Play `death_5_sean.wav` sound effect on player death.
- **Debug Cheat Bindings:**
  - Pressing **F1** cheats all items for the Hivemind Pistol synergy.
  - Pressing **F2** cheats all items for the Roadkill synergy.
  - Enabled cheat binds to work on exported release builds.

### Changed
- Replaced the term "Flesh" with "carne" in shop labels.
- Relocated Ygor's peaceful shop room from `room_ygor.tscn` to `Level1_Room12(Ygor1).tscn`.

### Removed
- Removed the obsolete `room_ygor.tscn` scene.
- Removed the obsolete `ShopMenu.tscn` and `shop_menu.gd` files.

### Fixed
- **Dynamic Projectile Lifetime:** Deferred the creation of the projectile lifetime timer by one frame in `projectile.gd` so that customized or synergy-upgraded lifetime values are correctly applied instead of being ignored.
- **Runtime Asset Preloading crash:** Verified if `.import` files exist before preloading/loading runtime assets to prevent Godot C++ parser crashes on first-run.

---

## [1.1.0] - 2026-06-09

### Added
- **Melee Weapons System:**
  - Implemented three new melee weapons: **Dagger** (fast, short range, low damage, minor knockback), **Mace** (slow, long range, high damage, massive knockback), and **Axe** (balanced stats).
  - Melee weapons swing animations implemented using Tweens.
  - Hit detection using Area2D, critical hit rate checks, and knockback forces.
  - Dynamic melee weapon swapping mapped to keys `4` (Dagger), `5` (Mace), and `6` (Axe).
  - Melee swing sound effects.
  - Added Codex entries, lore, and icons for all three melee weapons.
- **Weapon Rotation Pivot Alignment (Wrist Pivot):**
  - Updated weapon positioning so the weapon root centers exactly on the player's wrist pivot marker.
  - Automatically shifts children elements (sprites, collisions, particles) so the weapon pivots around its handle.
- **Frame-Based Offset Tracking:**
  - Added animation frame offset tracking to keep the weapon aligned with the player's hand during idle breathing animations.
- **Directional Dash Animations:**
  - Plays specific dash animations based on the 8 running directions (e.g. `Dash_up`, `Dash_left_down`, etc.).
- **Diagonal Run Animations:**
  - Added support for diagonal run animation sprites based on player's running direction.
- **Weapon & Item Synergy System:**
  - Added a central `SynergyManager` Autoload to calculate stat modifiers and weapon/projectile overrides.
  - **Hivemind Pistol Synergy:**
    - Triggers when equipping the **Pistol** with **Colmena** (+10% Crit), **Cerebro** (+1s lifetime, -5 spread), and **Cabeza Humana** (+1 projectile, +20% damage).
    - Modifiers: `+2` projectiles, `+3` damage, `+4.0s` lifetime, `-200` speed, `+1.5` attack speed.
    - Swaps weapon scene to `HivemindPistol.tscn` (incorporating conal auto-aim).
    - Swaps projectiles to teledirected mechanical bees (`BeeProjectile.tscn`).
    - **Conal Auto-Aim & Target-Locking:** Queries a conal Area2D on the weapon to lock onto the closest enemy inside the cone.
    - **Homing Steering Delay:** Bees fly straight out of the weapon muzzle for `0.3s` before they start homing on targets.
  - **Roadkill Synergy:**
    - Triggers when equipping the **Pistol** with **Motocicleta** (+30% attack speed, -2 damage), **Sierra Circular** (+20% Crit Damage, +20% Damage), and **Pulmones** (+20% attack speed, +50 knockback).
    - Modifiers: `+5` damage, `+150` projectile speed, `+1.0` attack speed, `+3` piercing.
    - Swaps weapon scene to `RoadkillPistol.tscn` (orange-yellow modulated layout).
    - Swaps projectiles to bouncing circular saw blades (`RoadkillProjectile.tscn`).
    - **Bouncing Projectiles:** Performs a 2D raycast to determine collision normals and bounces off walls up to 3 times, while piercing up to 3 enemies.

### Changed
- **Inventory UI Animations & Input:**
  - Replaced immediate toggles with smooth slide-up and slide-down transitions and background fade-in/fade-out.
  - Configured both `I` key and `Escape` key to close the menu.
  - Removed duplicate input polls to prevent rapid toggle loops.
- **Custom Textured Dash Cooldown Bar:**
  - Custom horizontal stamina bar progress bar texture supports.
- **Fixed Health Bar Scale Override:**
  - Retained designer-defined size and scale values for health bars instead of scaling them programmatically.

---

## [1.0.0] - 2026-04-11

### Added
- **Improved Weapon System:** The player's weapon now orbits the character and points directly to the mouse cursor (in the style of "Enter the Gungeon").
- **Enemy Logic:** Implemented an attack system for the "follower" enemy.
- **Visual Effects (Game Feel):**
  - Camera shake effect when taking damage.
  - Border visual effects on the screen when the player takes damage.
  - Screen fade transitions (fade-in / fade-out) for smooth transitions between scenes.
- **Room System:** Doors now lock when entering a room and unlock only after defeating all enemies in the room. Automated player spawn point assignment.
- **Economy and Gathering:** Implemented the "Scrap" currency system. Enemies drop Scrap upon defeat, and the player features a pickup area that smoothly attracts items.

### Changed
- **HUD / User Interface:** Replaced the original health bar with a `TextureProgressBar` and added a Scrap counter to the HUD.
- **Gameplay Loop:** Replaced the original wave-based survival system with a room progression and Scrap collection loop in instantiated rooms.
- **Projectile System:** Updated projectiles to use their own Sprite2D instead of procedural drawing, spawning cleanly from the weapon muzzle.

### Fixed
- Fixed player sprite flipping logic during dash when facing left.
- Fixed room and arena spawning issues at startup.
