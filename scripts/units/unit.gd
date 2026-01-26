# Unit.gd
# Represents a tactical unit in Warlord's Gambit.
# This script handles unit stats, combat actions, movement, and visual updates.
# Attach this to a CharacterBody2D scene with visual2D, CollisionShape2D, and Label children.
#
# UNIT TYPES:
# - HERO: Powerful leader, moves in all 8 directions
# - ELITE_WARRIOR: Melee specialist, extended movement range
# - ELITE_ARCHER: Ranged unit, high attack range
# - PAWN: Basic infantry, moves forward only
#
# Usage: Create unit scene, attach this script, call initialize() with UnitData

extends CharacterBody2D
class_name Unit

# ============================================================================
# NODE REFERENCES
# ============================================================================

## Reference to the unit's visual for visual display
@onready var visual: ColorRect = $Visual

## Reference to the collision shape for click detection
@onready var collision: CollisionShape2D = $CollisionShape2D

## Reference to the HP label displayed below the unit
@onready var hp_label: Label = $Label

# ============================================================================
# PROPERTIES
# ============================================================================

## Reference to the UnitData resource containing base stats and info
var unit_data: UnitData = null

## Current health points (can be modified by damage/healing)
var current_hp: int = 0

## Maximum health points (set from unit_data.base_hp + item bonuses)
var max_hp: int = 0

## Current attack power (base + item bonuses)
var current_atk: int = 0

## Current defense (base + item bonuses)
var current_def: int = 0

## Current speed (determines turn order)
var current_speed: int = 0

## Unit's position on the game board grid
var grid_position: Vector2i = Vector2i(0, 0)

## Faction this unit belongs to (e.g., "ROMAN", "BARBARIAN")
var faction: String = ""

## Type of unit (HERO, ELITE_WARRIOR, ELITE_ARCHER, PAWN)
var unit_type: String = ""

## Array of equipped ItemData resources
var equipped_items: Array = []

## Whether this unit has moved this turn
var has_moved: bool = false

## Whether this unit has attacked this turn
var has_attacked: bool = false

## True if controlled by player, false if enemy AI
var is_player_unit: bool = true

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when unit's HP reaches 0
## @param unit: Reference to this unit
signal died(unit)

## Emitted when unit takes damage
## @param amount: Damage taken
## @param remaining_hp: HP remaining after damage
signal took_damage(amount: int, remaining_hp: int)

## Emitted when this unit attacks another
## @param target: The unit being attacked
signal attacked(target)

## Emitted when unit moves to a new position
## @param from_pos: Previous grid position
## @param to_pos: New grid position
signal moved(from_pos: Vector2i, to_pos: Vector2i)

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initializes the unit with data from a UnitData resource
## Call this after instantiating the unit scene
## @param data: UnitData resource containing base stats
## @param pos: Starting grid position
## @param is_player: True if player-controlled, false if enemy
func initialize(data: UnitData, pos: Vector2i, is_player: bool) -> void:
	# Store references
	unit_data = data
	grid_position = pos
	is_player_unit = is_player
	
	# Safety check for null data
	if data == null:
		push_error("Unit.initialize() called with null UnitData!")
		return
	
	# Copy base stats from unit_data
	faction = data.faction
	unit_type = data.unit_type
	max_hp = data.base_hp
	current_hp = max_hp
	current_atk = data.base_atk
	current_def = data.base_def
	current_speed = data.base_speed
	
	# Set visual texture if available
	if visual and data.visual_texture:
		visual.texture = data.visual_texture
	
	# Update visual display
	update_visuals()
	
	print("Unit initialized: ", data.unit_name, " at ", pos)

# ============================================================================
# COMBAT METHODS
# ============================================================================

## Applies damage to this unit
## Damage is always at least 1 (no 0 damage hits)
## @param amount: Raw damage amount before any reduction
## @return: Remaining HP after damage
func take_damage(amount: int) -> int:
	# Ensure minimum 1 damage (prevents invincibility)
	var damage: int = max(1, amount)
	
	# Apply damage, don't go below 0
	current_hp -= damage
	current_hp = max(0, current_hp)
	
	# Emit signal for UI updates, sound effects, etc.
	took_damage.emit(damage, current_hp)
	
	# Update visual display (HP label, damage tint)
	update_visuals()
	
	# Check if unit died
	if current_hp <= 0:
		died.emit(self)
		print(unit_data.unit_name if unit_data else "Unit", " has died!")
	
	return current_hp


## Heals the unit by the specified amount
## Cannot exceed max_hp
## @param amount: Amount of HP to restore
func heal(amount: int) -> void:
	var old_hp = current_hp
	
	# Add HP but cap at maximum
	current_hp += amount
	current_hp = min(current_hp, max_hp)
	
	# Update visual display
	update_visuals()
	
	print("Healed ", current_hp - old_hp, " HP. Now at ", current_hp, "/", max_hp)


## Performs an attack against a target unit
## Calculates damage using ATK vs DEF formula with 10% crit chance
## @param target: The Unit to attack
## @return: Dictionary with damage, is_crit, and killed info
func attack(target) -> Dictionary:
	# Safety check
	if target == null:
		push_error("Cannot attack null target!")
		return {"damage": 0, "is_crit": false, "killed": false}
	
	# Calculate base damage: ATK - DEF, minimum 1
	var base_damage: int = max(1, current_atk - target.current_def)
	
	# 10% critical hit chance for double damage
	var is_crit: bool = randf() < 0.1
	var final_damage: int = base_damage * 2 if is_crit else base_damage
	
	# Apply damage to target and get remaining HP
	var remaining_hp: int = target.take_damage(final_damage)
	
	# Emit signal and mark as having attacked
	attacked.emit(target)
	has_attacked = true
	
	# Log combat result
	var crit_text = " CRITICAL!" if is_crit else ""
	print(unit_data.unit_name if unit_data else "Unit", " dealt ", final_damage, " damage!", crit_text)
	
	return {
		"damage": final_damage,
		"is_crit": is_crit,
		"killed": remaining_hp <= 0
	}

# ============================================================================
# MOVEMENT METHODS
# ============================================================================

## Returns all valid grid positions this unit can move to
## Movement patterns vary by unit_type
## @param board_size: Size of the game board (typically 10)
## @return: Array of valid Vector2i positions
func get_valid_moves(board_size: int) -> Array[Vector2i]:
	var valid_moves: Array[Vector2i] = []
	
	# Get movement range from unit_data or default to 1
	var range_val: int = unit_data.movement_range if unit_data else 1
	
	match unit_type:
		"HERO":
			# Hero: Moves in all 8 directions within range
			# Like a king in chess but potentially with extended range
			for dx in range(-range_val, range_val + 1):
				for dy in range(-range_val, range_val + 1):
					if dx == 0 and dy == 0:
						continue # Skip current position
					var new_pos = Vector2i(grid_position.x + dx, grid_position.y + dy)
					if _is_within_bounds(new_pos, board_size):
						valid_moves.append(new_pos)
		
		"ELITE_WARRIOR", "ELITE_ARCHER":
			# Elites: Extended movement range (typically 2 tiles)
			# Can move orthogonally or diagonally
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if dx == 0 and dy == 0:
						continue # Skip current position
					var new_pos = Vector2i(grid_position.x + dx, grid_position.y + dy)
					if _is_within_bounds(new_pos, board_size):
						valid_moves.append(new_pos)
		
		"PAWN":
			# Pawn: Moves 1 tile forward only
			# Forward is UP (-Y) for player, DOWN (+Y) for enemy
			var forward: int = -1 if is_player_unit else 1
			var new_pos = Vector2i(grid_position.x, grid_position.y + forward)
			if _is_within_bounds(new_pos, board_size):
				valid_moves.append(new_pos)
		
		_:
			# Default: 1 tile in all directions
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var new_pos = Vector2i(grid_position.x + dx, grid_position.y + dy)
					if _is_within_bounds(new_pos, board_size):
						valid_moves.append(new_pos)
	
	return valid_moves


## Helper function to check if position is within board bounds
## @param pos: Position to check
## @param board_size: Size of the board
## @return: True if position is valid
func _is_within_bounds(pos: Vector2i, board_size: int) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size


## Returns the attack range for this unit
## @return: Number of tiles this unit can attack
func get_attack_range() -> int:
	# Use unit_data's attack_range if available
	if unit_data:
		return unit_data.attack_range
	
	# Fallback based on unit type
	match unit_type:
		"ELITE_ARCHER":
			return 3 # Archers have extended range
		_:
			return 1 # Melee range


## Checks if a target position is within attack range
## Uses Manhattan distance (no diagonal shortcuts)
## @param target_pos: Grid position of potential target
## @return: True if target is in range
func can_attack(target_pos: Vector2i) -> bool:
	# Calculate Manhattan distance (|dx| + |dy|)
	var distance: int = abs(target_pos.x - grid_position.x) + abs(target_pos.y - grid_position.y)
	return distance <= get_attack_range()

# ============================================================================
# TURN STATE MANAGEMENT
# ============================================================================

## Moves the unit to a new grid position
## @param new_pos: The target grid position
func move_to(new_pos: Vector2i) -> void:
	var old_pos = grid_position
	grid_position = new_pos
	has_moved = true
	moved.emit(old_pos, new_pos)


## Resets unit's turn state for a new turn
## Called at the start of each turn by TurnManager
func reset_turn_state() -> void:
	has_moved = false
	has_attacked = false

# ============================================================================
# VISUAL UPDATES
# ============================================================================

## Updates all visual elements (HP label, visual tint)
## Call this after any stat changes
func update_visuals() -> void:
	# Update HP label text
	if hp_label:
		hp_label.text = "HP: %d/%d" % [current_hp, max_hp]
	
	# Apply damage tint when HP is low
	if visual:
		var hp_percent: float = float(current_hp) / float(max_hp) if max_hp > 0 else 1.0
		
		if hp_percent < 0.3:
			# Red tint when below 30% HP - unit is in danger!
			visual.modulate = Color(1.0, 0.5, 0.5)
		else:
			# Normal color when healthy
			visual.modulate = Color(1.0, 1.0, 1.0)
	
	# Placeholder coloring when no visual texture is assigned
	# This helps with prototyping before art is ready
	if visual and not visual.texture:
		var base_color: Color
		
		# Color based on faction
		match faction:
			"ROMAN":
				base_color = Color.RED
			"BARBARIAN":
				base_color = Color.ORANGE
			"SAMURAI":
				base_color = Color.BLUE
			"UNDEAD":
				base_color = Color.PURPLE
			"DESERT":
				base_color = Color.YELLOW
			"VIKING":
				base_color = Color.CYAN
			_:
				base_color = Color.GRAY
		
		# Darken enemy units to distinguish from player units
		if not is_player_unit:
			base_color = base_color.darkened(0.3)
		
		visual.modulate = base_color
