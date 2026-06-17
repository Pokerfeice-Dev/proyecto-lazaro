# Game Design Document: Proyecto Lázaro (formerly Project Frankenstein)

This document serves as the complete technical and game design specification (GDD) for **Proyecto Lázaro**, a fast-paced 2D roguelike action shooter/melee game built in **Godot 4**. It provides an exhaustive overview of the systems, classes, stats, items, synergies, and enemies in the game.

---

## 1. Executive Summary & Core Mechanics

*   **Engine**: Godot 4.x (using GDScript).
*   **Genre**: Top-Down Action Roguelike (similar to *Enter the Gungeon* and *Hades*).
*   **Aesthetics**: Cyberpunk, bio-organic mutations, mechanical implants.
*   **Controls**:
    *   **Movement**: `W`, `A`, `S`, `D` keys.
    *   **Dashing**: `Space` key. Invulnerability frames, directional animation states, and stamina/cooldown bar on HUD.
    *   **Weapon Orbit**: Ranged weapons pivot around the player's wrist marker and orbit pointing towards the mouse cursor.
    *   **Inventory Toggle**: `I` key to slide up/down the equipment panel.
    *   **Debug Menu Warp**: `F6` key to transition to the sandbox test scene.
    *   **Synergy Cheat Hotkeys**: `F1` (Hivemind), `F2` (Roadkill), `F3` (Bestia de Caza), `F4` (Trituradora Biomecánica), `F5` (Minigun).

---

## 2. Economy & Run Progression

### Currencies
1.  **Scrap (Chatarra)**:
    *   Persists across runs and deaths.
    *   Dropped by enemies. Magnetically attracted to the player when close.
    *   Used in the persistent upgrade menu to improve base stats.
    *   Tracked globally in `GameData.scrap`.
2.  **Carne (Flesh)**:
    *   Resets to `0` upon starting a new run or dying.
    *   Used as currency inside runs for **Ygor's peaceful shop**.
    *   Tracked globally in `GameData.flesh`.

### Rooms & Level Progression
Runs progress room-by-room, managed by `GameData.gd`:
*   **Lab Room (`lab_room.tscn`)**: The starting safe zone/hub.
*   **Progression Pool**: Standard rooms are loaded from `res://Scenes/Rooms/Level1_Room*.tscn`.
*   **Door Locking**: Doors lock automatically when entering a room. Spawn points trigger waves of enemies. Doors unlock, and a reward pedestal/chest spawns once all enemies in the room are defeated.
*   **Shop/Treasure Rooms**: Roll at room intervals (e.g., room 3, 6).
*   **Boss Room (`Level1_Room15-BossFight.tscn`)**: Enters a final arena fight after 7 to 10 rooms.

---

## 3. Implants & Upgrade Items

The player has 11 equipment slots: `MAIN_W1`, `MAIN_W2`, `MAIN_W3` (primary ranged upgrades), `SEC_W1`, `SEC_W2`, `SEC_W3` (secondary melee upgrades), `TORSO`, `ARM_L`, `ARM_R`, `LEG_L`, `LEG_R` (body parts).

### A. Body Parts (12 Items)

#### Torsos
1.  **Blindaje de Torso** (Base): Standard chestplate armor.
2.  **Torso Blindado**: `+25%` Max HP, `+2` Defense, `-10%` Move Speed, `-15%` Dash Speed.
3.  **Torso Espinado**: `+10%` Max HP, `+1` Defense. Knocks back enemies within 80px when the player takes damage.
4.  **Torso Ligero**: `+10%` Move Speed, `+15%` Dash Speed, `-30%` Dash Cooldown, `-15%` Max HP, `-1` Defense.

#### Legs
1.  **Servobotas de Combate** (Base): Standard speed boots.
2.  **Piernas Rodantes**: `+15%` Move Speed, `+15%` Dash Speed, `-20%` Dash Cooldown, `-10%` Max HP.
3.  **Piernas Caninas**: `+10%` Move Speed, `+25%` Attack Speed, `+1` Defense.
4.  **Piernas Biónicas**: `+10%` Move Speed, `+10%` Dash Speed, `+1` Health on Carne collection, `-15%` Max HP.

#### Arms
1.  **Módulo de Brazos** (Base): Standard strength arms.
2.  **Brazo Reforzado**: `+10%` Melee Knockback, `+1` Defense.
3.  **Brazo Ligero**: `+10%` Attack Speed, `-10%` Max HP.
4.  **Brazo Armado (Cuchilla)**: `+20%` Melee Reach (Swing range), `+15%` Attack Speed, `-1` Defense.

---

### B. Weapon Upgrades (9 Items)
These items go into weapon-specific inventory slots. Ranged upgrades only affect primary weapons; melee upgrades only affect secondary weapons.

1.  **Licuadora Mezcladora**: `+Damage`, `+Knockback`, `-Projectile Speed`.
2.  **Aguijón Mecánico**: `+Attack Speed`, `+Crit Damage`.
3.  **Cerebro Sintético**: `+Crit Chance`, `+Damage`.
4.  **Cabeza de Sabueso Metálica**: `+Armor`, `+Damage`.
5.  **Pulmones Bio-Asistidos**: `+Projectile Speed`, `+Projectile Range/Lifetime`.
6.  **Núcleo de Motocicleta**: `+Damage`, `+Knockback`.
7.  **Colmena Bio-Mecánica**: `+Crit Chance`.
8.  **Cabeza Humana Preservada**: `+Projectile Count`, `+Damage`.
9.  **Sierra Circular**: `+Damage`, `+Crit Damage`.

---

## 4. Weapon Arsenal

### Primary Ranged Weapons
*   **Pistol (`pistol.tscn`)**: Default gun. Single projectile, accurate, balanced.
*   **Uzi (`uzi.tscn`)**: Fast automatic fire rate, wide cone spread, lower damage.
*   **Shotgun (`shotgun.tscn`)**: Shoots a burst of 4 spread pellets per shot.

### Secondary Melee Weapons
*   **Dagger (`dagger.tscn`)**: Fast slash frequency, short reach, low knockback.
*   **Mace (`mace.tscn`)**: Heavy swing, long reach, massive damage, high knockback force.
*   **Axe (`axe.tscn`)**: Balanced swing rate, damage, and sweep area.

---

## 5. Synergies

Calculated via the `SynergyManager` Autoload:

### 1. Pistola Mente Colmena
*   **Requirements**: Pistol (equipped) + Colmena + Cerebro + Cabeza Humana.
*   **Effects**:
    *   Replaces weapon scene with `HivemindPistol.tscn`.
    *   Fires mechanical homing bees (`BeeProjectile.tscn`).
    *   **Bee Behavior**: Flies straight out of the muzzle for `0.3s`, then targets the nearest enemy inside a frontal cone and locks on.
    *   **Stats**: `+2` bullets, `+3` damage, `+4s` bullet lifetime, `-200` speed, `+1.5` fire rate.

### 2. Roadkill
*   **Requirements**: Pistol (equipped) + Motocicleta + Sierra Circular + Pulmones.
*   **Effects**:
    *   Replaces weapon scene with `RoadkillPistol.tscn`.
    *   Fires circular saw blades (`RoadkillProjectile.tscn`).
    *   **Blade Behavior**: Rays check collision normals on walls, bouncing off obstacles up to 3 times while piercing up to 3 enemies.
    *   **Stats**: `+5` damage, `+150` projectile speed, `+1.0` attack speed, `+3` piercing.

### 3. Bestia de Caza (Instinto Depredador)
*   **Requirements**: Piernas Caninas + Brazo Armado + Torso Ligero.
*   **Effects**:
    *   Prevents player from using ranged weapons. Left click and right click both swing melee weapons (dual-wielding).
    *   Performing a dash triggers **Furia (Fury)** for 3 seconds:
        *   Player character turns red.
        *   Walks/passes through small enemies.
        *   Melee slashes generate a circle AoE shockwave.
        *   `+50%` Attack Speed.

### 4. Trituradora Biomecánica (Carga de Impacto)
*   **Requirements**: Torso Blindado + Piernas Rodantes + Brazo Reforzado.
*   **Effects**:
    *   Walking accumulates kinetic energy (slow rate).
    *   At 100% charge:
        *   The next dash generates a shockwave pushing enemies back and dealing damage in an area.
        *   Grants `2` seconds of complete invulnerability.

---

## 6. Bestiary (Enemy Types)

1.  **Mutante Seguidor (Follower)**: Basic melee chaser that pursues the player when alerted.
2.  **Mutante Tirador (Shooter)**: Fires espores/acid projectiles in a straight line at the player.
3.  **Mutante Coloso (Tank)**: Giant health pool, slow speed, heavy contact damage.
4.  **Torreta de Seguridad (Turret)**: Static mechanical base that fires at the player when inside its radius.
5.  **Invocador (Summoner)**:
    *   Spawns starting from the 5th room.
    *   Maintains distance from the player and summons up to 2 mechanical bee minions at a time.
6.  **Abeja Invocada (Bee Minion)**:
    *   Approaches the player, projects a line-of-sight laser warning indicator, and dashes in a straight line at high speed.
7.  **Génesis (Boss)**: Hard-hitting end boss. Multiple bullet-hell patterns and a massive boss health bar.

---

## 7. peaceful Zone: Ygor's Shop

*   Located in `Level1_Room12(Ygor1).tscn`.
*   Interactive physical shop:
    *   **Heal (Heart)**: Costs `20` carne. Restores `25%` of player's missing health.
    *   **Random Body Item**: Costs `30` carne.
    *   **Random Weapon Item**: Costs `40` carne.
*   NPC interaction: Clicking/standing near Ygor prompts dialogue balloons containing floating text instead of static menus.

---

## 8. Sandbox / Debug Scene (`debug_scene.tscn`)

Activated at any time by pressing **F6** in a build.
*   **State Persistence**: Saves the exact room and state the player left. Pressing F6 inside the debug scene loads you back into the game smoothly.
*   **Collapsible Panel**: Features a dynamic panel sliding on the right screen edge using Godot Tweens.
*   **Sandbox Tabs**:
    1.  **Cheats**: Refill HP, toggle invulnerable God Mode (persists across runs/rooms), add currency, kill all active enemies in the room, cheat Minigun synergy.
    2.  **Weapons**: Instantly spawn and equip any primary ranged or secondary melee weapon.
    3.  **Items**: Add any of the 12 body implants or 9 weapon upgrades to the player inventory (or bulk-add all 21 items).
    4.  **Enemies**: Spawn any of the 7 enemy types at a safe offset from the player.

---

## 9. Codebase Architecture & Singletons

*   **SceneTransition (`scene_transition.gd`)**: CanvasLayer autoload. Manages fading transitions (`Tween` black overlay) and background music states for main menu, peace zones, and combat.
*   **GameData (`game_data.gd`)**: Autoload. Persists player stats, active items, weapon upgrades, codex unlocks, slots, and run progression variables.
*   **SynergyManager (`synergy_manager.gd`)**: Autoload. Tracks item lists and weapon IDs to trigger stat and scene overrides.
*   **HUD (`hud.gd`)**: Synchronizes player health, stamina, weapons HUD, scrap, and flesh counters using signal events (`health_changed`, `scrap_changed`, etc.).
