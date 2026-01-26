# Warlord's Gambit - Tactical Roguelike

## Core Mechanics

- Turn-based tactical combat on 10x10 grid
- Chess/Shogi-inspired unit movement
- RPG stats: HP, ATK, DEF, SPD
- Auto-battle with pre-positioning strategy
- Roguelike progression with permadeath

## Factions

1. Romans - Defensive, formation-focused
2. Barbarians - Aggressive, high damage
3. Samurai - Counter-based, precision
4. Undead - Revival mechanics
5. Desert Kingdom - Mobility, illusions
6. Vikings - Charge-focused

## Unit Types

- Hero: Powerful leader (1 per army)
- Elite: Specialized units (2-3 per army)
- Pawns: Basic infantry (6-10 per army)

## Systems

- Board: 10x10 grid with terrain types
- Combat: Damage = max(1, ATK - DEF)
- Items: Equipment with stat bonuses
- Formations: Position-based buffs
- Progression: Unlock units/items between runs

```

Save it (Ctrl+S)

---

# 🎯 PHASE 1: RESOURCE SCRIPTS (Core Data)

## **STEP 6: Create UnitData Resource**

### **In VS Code:**

1. Create file: `scripts/core/unit_data.gd`
2. Open Copilot Chat: **Ctrl+Shift+I**
3. Paste this prompt:
```

Create a Godot 4.3 GDScript resource class called UnitData that extends Resource.

Requirements:

- Use @export for all variables (so they appear in Godot inspector)
- Use proper Godot 4 type hints (int, float, String, etc.)

Properties needed:
@export var unit_name: String = ""
@export var unit_type: String = "PAWN" # HERO, ELITE_WARRIOR, ELITE_ARCHER, PAWN
@export var faction: String = "ROMAN"
@export var base_hp: int = 30
@export var base_atk: int = 10
@export var base_def: int = 5
@export var base_speed: int = 5
@export var movement_range: int = 1
@export var attack_range: int = 1
@export var sprite_texture: Texture2D
@export var unit_description: String = ""
@export_multiline var abilities: String = ""

Add class_name so it appears in Godot's resource picker.
Add helpful comments explaining each property.
Include default values appropriate for a basic pawn unit.

File should start with:
extends Resource
class_name UnitData

```

**Copilot will generate the complete script!**

4. **Copy the generated code** into `unit_data.gd`
5. **Save** (Ctrl+S)

---

## **STEP 7: Create FormationData Resource**

### **Create file:** `scripts/core/formation_data.gd`

### **Copilot Chat Prompt:**
```

Create a Godot 4.3 resource class called FormationData that extends Resource.

Properties:
@export var formation_name: String = ""
@export var formation_type: String = "PHALANX" # PHALANX, WEDGE, SCATTERED, etc.
@export var description: String = ""
@export var atk_bonus: int = 0
@export var def_bonus: int = 0
@export var speed_bonus: int = 0
@export var special_effect: String = "" # Description of special formation ability

Add class_name FormationData
Include comments explaining how formations work (position-based bonuses).

```

Copy code → paste into file → save

---

## **STEP 8: Create ItemData Resource**

### **Create file:** `scripts/core/item_data.gd`

### **Copilot Chat Prompt:**
```

Create a Godot 4.3 resource class called ItemData that extends Resource.

Properties:
@export var item_name: String = ""
@export_enum("COMMON", "UNCOMMON", "RARE", "LEGENDARY") var rarity: String = "COMMON"
@export_enum("WEAPON", "ARMOR", "ACCESSORY") var slot_type: String = "WEAPON"
@export var hp_bonus: int = 0
@export var atk_bonus: int = 0
@export var def_bonus: int = 0
@export var speed_bonus: int = 0
@export var special_effect: String = ""
@export var description: String = ""
@export var icon: Texture2D

Add class_name ItemData
Include comments about how items enhance unit stats.

```

Copy → paste → save

---

## **STEP 9: Verify Resources in Godot**

### **Switch back to Godot:**

1. **FileSystem panel** → Navigate to `scripts/core/`
2. You should see 3 .gd files with icons
3. Click `unit_data.gd` → Should see "class_name: UnitData" in script

**If you see errors:** Press Ctrl+Shift+R in Godot to reload scripts

---

# 🎮 PHASE 2: CORE GAME SYSTEMS

## **STEP 10: Create Board System**

### **Manual in Godot:**

1. **Scene → New Scene**
2. **Root type:** Select **Node2D**
3. **Rename root** to `Board`
4. **Add child nodes:**
   - Right-click Board → Add Child Node → Search "TileMap" → Add
   - Right-click Board → Add Child Node → Search "TileMap" → Add (for highlights)
5. **Rename TileMaps:**
   - First one: `TileMapMain`
   - Second one: `TileMapHighlight`
6. **Save scene:** Ctrl+S → `scenes/board/board.tscn`

### **In VS Code:**

Create file: `scripts/core/board.gd`

### **Copilot Chat Prompt:**
```

Create a Board.gd script for Godot 4.3 that manages a tactical game board.

The script should extend Node2D and have these features:

CONSTANTS:

- BOARD_SIZE: int = 10 (10x10 grid)
- TILE_SIZE: int = 64 (each tile is 64x64 pixels)

NODE REFERENCES:

- @onready var tilemap_main: TileMap = $TileMapMain
- @onready var tilemap_highlight: TileMap = $TileMapHighlight

PROPERTIES:

- var grid_data: Array = [] # 2D array storing what's on each tile
- var selected_position: Vector2i = Vector2i(-1, -1)

SIGNALS:

- signal tile_clicked(grid_pos: Vector2i)

METHODS:

- func \_ready(): Initialize the grid_data array as 10x10
- func world_to_grid(world_pos: Vector2) -> Vector2i: Convert pixel position to grid coordinates
- func grid_to_world(grid_pos: Vector2i) -> Vector2: Convert grid to pixel position
- func is_valid_position(grid_pos: Vector2i) -> bool: Check if position is within board bounds
- func get_tile_data(grid_pos: Vector2i): Return what's stored at that grid position
- func set_tile_data(grid_pos: Vector2i, data): Store data at grid position
- func highlight_tiles(positions: Array[Vector2i], color: Color): Highlight multiple tiles
- func clear_highlights(): Remove all highlights
- func \_input(event: InputEvent): Handle mouse clicks, emit tile_clicked signal

Include detailed comments explaining coordinate conversion.
Use Godot 4 syntax with proper type hints.

```

Copy generated code → paste into `board.gd` → save

---

### **Attach Script to Board Scene:**

**In Godot:**
1. Open `scenes/board/board.tscn`
2. Select **Board** root node
3. **Inspector panel** → Script → Click folder icon
4. Navigate to `scripts/core/board.gd` → Select it
5. Save scene (Ctrl+S)

---

## **STEP 11: Create Unit Scene & Script**

### **Manual in Godot:**

1. **Scene → New Scene**
2. **Root:** Select **CharacterBody2D**
3. **Rename** to `Unit`
4. **Add children:**
   - Right-click Unit → Add Child → **Sprite2D** (for unit visual)
   - Right-click Unit → Add Child → **CollisionShape2D** (for clicking)
   - Right-click Unit → Add Child → **Label** (for HP display)
5. **Configure nodes:**
   - Select **CollisionShape2D**
   - Inspector → Shape → **New RectangleShape2D**
   - Size: 60x60
   - Position **Label** below sprite (Y: 40)
6. **Save:** `scenes/units/unit.tscn`

### **In VS Code:**

Create file: `scripts/units/unit.gd`

### **Copilot Chat Prompt:**
```

Create a Unit.gd script for Godot 4.3 that extends CharacterBody2D.

This represents a tactical unit in a turn-based game.

NODE REFERENCES:

- @onready var sprite: Sprite2D = $Sprite2D
- @onready var hp_label: Label = $Label

PROPERTIES:

- var unit_data: UnitData # Reference to UnitData resource
- var current_hp: int = 0
- var max_hp: int = 0
- var current_atk: int = 0
- var current_def: int = 0
- var current_speed: int = 0
- var grid_position: Vector2i = Vector2i(0, 0)
- var faction: String = ""
- var unit_type: String = ""
- var equipped_items: Array[ItemData] = []
- var has_moved: bool = false
- var has_attacked: bool = false
- var is_player_unit: bool = true

SIGNALS:

- signal died(unit: Unit)
- signal took_damage(amount: int, remaining_hp: int)
- signal attacked(target: Unit)
- signal moved(from_pos: Vector2i, to_pos: Vector2i)

METHODS:

- func initialize(data: UnitData, pos: Vector2i, is_player: bool):
  Set up unit from UnitData resource, set grid position, update visuals
- func take_damage(amount: int) -> int:
  Reduce current_hp by amount (minimum 1 damage)
  Update HP label
  Emit took_damage signal
  Check if dead, emit died signal if hp <= 0
  Return remaining HP
- func heal(amount: int):
  Increase HP (max = max_hp)
  Update HP label
- func attack(target: Unit) -> Dictionary:
  Calculate damage: max(1, self.current_atk - target.current_def)
  10% chance for critical (2x damage)
  Emit attacked signal
  Call target.take_damage()
  Return {damage: int, is_crit: bool, killed: bool}
- func get_valid_moves(board_size: int) -> Array[Vector2i]:
  Based on unit_type, return valid grid positions:
  - HERO: 1 tile in any direction (8 surrounding tiles)
  - ELITE_WARRIOR: 2 tiles orthogonally or diagonally
  - ELITE_ARCHER: Same as warrior (moves 2)
  - PAWN: 1 tile forward only (up if player, down if enemy)
    Check board bounds
- func get_attack_range() -> int:
  Return attack range based on unit_type:
  - HERO: 1
  - ELITE_WARRIOR: 1
  - ELITE_ARCHER: 3
  - PAWN: 1
- func can_attack(target_pos: Vector2i) -> bool:
  Check if target_pos is within attack range from current position
- func reset_turn_state():
  Set has_moved and has_attacked to false
- func update_visuals():
  Update hp_label text to show "HP: current/max"
  Change sprite modulate if low HP (red tint if hp < 30%)

Include detailed comments.
Use Godot 4 syntax with type hints.
Handle null cases safely.

```

Copy code → paste into `scripts/units/unit.gd` → save

---

### **Attach Script:**

**In Godot:**
1. Open `scenes/units/unit.tscn`
2. Select **Unit** root node
3. Inspector → Script → Attach `scripts/units/unit.gd`
4. Save

---

## **STEP 12: Create Combat Manager Singleton**

### **In VS Code:**

Create file: `scripts/systems/combat_manager.gd`

### **Copilot Chat Prompt:**
```

Create a CombatManager.gd autoload singleton for Godot 4.3.

This manages all combat calculations in the game.

Extends Node (not CharacterBody2D)

SIGNALS:

- signal combat_started(attacker: Unit, defender: Unit)
- signal combat_resolved(result: Dictionary)
- signal unit_died(unit: Unit)

METHODS:

- func calculate_damage(attacker_atk: int, defender_def: int) -> Dictionary:
  Base damage = max(1, attacker_atk - defender_def)
  10% chance for critical hit (2x damage)
  Return {damage: int, is_crit: bool}
- func resolve_combat(attacker: Unit, defender: Unit) -> Dictionary:
  Emit combat_started signal
  Call calculate_damage()
  Apply damage to defender using defender.take_damage()
  Check if defender died
  Emit combat_resolved signal
  Return {
  damage_dealt: int,
  is_crit: bool,
  defender_survived: bool,
  defender_hp: int
  }
- func can_units_fight(attacker: Unit, defender: Unit) -> bool:
  Check if attacker has_attacked already
  Check if defender is still alive
  Check if they're on different factions
  Return true only if combat is valid

Include detailed comments.
Add print statements for debugging (can be removed later).

```

Copy → paste → save

---

### **Register as Autoload (Singleton):**

**In Godot:**
1. **Project → Project Settings**
2. Click **"Autoload"** tab
3. Click folder icon next to "Path:"
4. Navigate to `scripts/systems/combat_manager.gd` → Open
5. **Node Name:** Should auto-fill as `CombatManager`
6. Click **"Add"**
7. Click **"Close"**

**Verify:** You should see `CombatManager` in the autoload list

---

## **STEP 13: Create Turn Manager Singleton**

### **In VS Code:**

Create file: `scripts/systems/turn_manager.gd`

### **Copilot Chat Prompt:**
```

Create a TurnManager.gd autoload singleton for Godot 4.3.

Manages turn order and game phases.

Extends Node

ENUM:
enum Phase {PLAYER_PLANNING, PLAYER_ACTION, ENEMY_TURN, BATTLE_END}

PROPERTIES:

- var current_turn: int = 1
- var current_phase: Phase = Phase.PLAYER_PLANNING
- var active_faction: String = "PLAYER"

SIGNALS:

- signal turn_started(faction: String, turn_number: int)
- signal turn_ended(faction: String)
- signal phase_changed(new_phase: Phase)

METHODS:

- func start_turn(faction: String):
  Set active_faction
  Increment turn number if player turn
  Set phase to PLAYER_PLANNING or ENEMY_TURN based on faction
  Emit turn_started
- func end_turn():
  Emit turn_ended
  Switch faction (PLAYER <-> ENEMY)
  Call start_turn() for next faction
- func set_phase(new_phase: Phase):
  current_phase = new_phase
  Emit phase_changed
- func reset_all_units(units: Array):
  Call reset_turn_state() on each unit in array
- func can_unit_act(unit: Unit) -> bool:
  Return true only if:
  - unit.faction matches active_faction
  - current_phase allows actions
  - unit is alive

Include detailed comments.
