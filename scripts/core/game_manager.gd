# GameManager.gd
# Main game controller for Warlord's Gambit.
# This script manages the core game loop, coordinating between all game systems.
#
# RESPONSIBILITIES:
# - Board initialization and setup
# - Unit spawning and tracking for both player and enemy
# - Input handling (tile clicks, unit selection, movement, attacks)
# - Coordination with TurnManager and CombatManager singletons
# - Win/loss condition checking
#
# USAGE:
# Attach this script to the root Node2D of your main game scene.
# Ensure Board is a child node named "Board".

extends Node2D

# ============================================================================
# NODE REFERENCES
# ============================================================================

## Reference to the Board scene (child node)
## Board handles tile display, grid data, and tile click detection
@onready var board: Node2D = $Board

## Reference to the GameUI canvas layer for HUD updates
@onready var ui: GameUI = $GameUI


# ============================================================================
# ENUMS
# ============================================================================

## Game states that control input handling and available actions
## SELECTING: Player can click on their units to select them
## MOVING: Player has selected a unit and can click to move it
## ATTACKING: Unit has moved and can attack nearby enemies
## ENEMY_TURN: AI is controlling enemy units
## GAME_OVER: Victory or defeat, no more actions
enum GameState {
	SELECTING,
	MOVING,
	ATTACKING,
	ENEMY_TURN,
	GAME_OVER
}

# ============================================================================
# PROPERTIES
# ============================================================================

## Array of all player-controlled units
var player_units: Array = []

## Array of all enemy units
var enemy_units: Array = []

## Combined array of all units on the board
var all_units: Array = []

## Currently selected unit (null if none selected)
var selected_unit = null

## Valid grid positions the selected unit can move to
var valid_move_positions: Array[Vector2i] = []

## Valid grid positions containing enemies the selected unit can attack
var valid_attack_positions: Array[Vector2i] = []

## Current game state controlling input behavior
var current_state: GameState = GameState.SELECTING

# ============================================================================
# INITIALIZATION
# ============================================================================

## Called when node enters scene tree
## Sets up the game board, spawns units, and connects signals
## Called when node enters scene tree
## Sets up the game board, spawns units, and connects signals
func _ready() -> void:
	print("[GameManager] Initializing game...")
	
	# Reset TurnManager state (important for scene reloads)
	TurnManager.reset_game()
	
	# Setup in order: board -> units -> signals -> start turn
	setup_board()
	board.generate_random_terrain()
	
	# Check if this is a roguelike run with deployed units
	if RunManager.run_active and RunManager.active_squad.size() > 0:
		print("[GameManager] Spawning player's deployed squad...")
		spawn_deployed_units()
	else:
		print("[GameManager] No active run - spawning test units...")
		spawn_test_units()
	
	connect_signals()
	
	# Start the first turn
	TurnManager.start_turn("PLAYER")
	
	print("[GameManager] Game initialization complete!")

## Connects to the board's tile_clicked signal for input handling
func setup_board() -> void:
	if board:
		# Connect to board's tile click signal
		board.tile_clicked.connect(_on_tile_clicked)
		print("[GameManager] Board setup complete - connected to tile_clicked signal")
	else:
		push_error("[GameManager] ERROR: Board node not found! Make sure Board is a child node.")


## Spawns test units for both player and enemy sides
## Loads UnitData resources and creates mixed armies for both factions
func spawn_test_units() -> void:
	print("[GameManager] Spawning test units...")
	
	# Load the Unit scene
	var unit_scene = preload("res://scenes/units/unit.tscn")
	
	if unit_scene == null:
		push_error("[GameManager] ERROR: Could not load unit scene!")
		return
	
	# ----- DEFINE UNIT DATA PATHS -----
	const UNIT_DATA_PATH = "res://resources/unit_data/"
	
	# Player army composition (Roman faction)
	var player_army_data: Array[Dictionary] = [
		{"resource": "roman_centurion.tres", "col": 4, "row": 8}, # Hero - center
		{"resource": "roman_legionnaire.tres", "col": 3, "row": 8}, # Elite Warrior - left of hero
		{"resource": "roman_archer.tres", "col": 5, "row": 7}, # Elite Archer - back row
		{"resource": "roman_pawn.tres", "col": 2, "row": 9}, # Pawn 1 - front left
		{"resource": "roman_pawn.tres", "col": 6, "row": 9}, # Pawn 2 - front right
	]
	
	# Enemy army composition (Barbarian faction)
	var enemy_army_data: Array[Dictionary] = [
		{"resource": "barbarian_warlord.tres", "col": 4, "row": 1}, # Hero - center
		{"resource": "barbarian_berserker.tres", "col": 5, "row": 1}, # Elite Warrior - right of hero
		{"resource": "barbarian_hunter.tres", "col": 3, "row": 2}, # Elite Archer - back row
		{"resource": "barbarian_pawn.tres", "col": 2, "row": 0}, # Pawn 1 - front left
		{"resource": "barbarian_pawn.tres", "col": 7, "row": 0}, # Pawn 2 - front right
	]
	
	# ----- SPAWN PLAYER UNITS (bottom side of board, rows 7-9) -----
	print("[GameManager] Spawning player army (Roman)...")
	for unit_info in player_army_data:
		var unit_data = _load_unit_data(UNIT_DATA_PATH + unit_info["resource"])
		if unit_data == null:
			push_warning("[GameManager] Skipping unit - could not load: " + unit_info["resource"])
			continue
		
		var grid_pos = Vector2i(unit_info["col"], unit_info["row"])
		var unit = _spawn_unit(unit_scene, unit_data, grid_pos, true)
		
		if unit:
			player_units.append(unit)
			all_units.append(unit)
			print("[GameManager] Spawned player %s (%s) at: %s" % [unit_data.unit_name, unit_data.unit_type, grid_pos])
	
	# ----- SPAWN ENEMY UNITS (top side of board, rows 0-2) -----
	print("[GameManager] Spawning enemy army (Barbarian)...")
	for unit_info in enemy_army_data:
		var unit_data = _load_unit_data(UNIT_DATA_PATH + unit_info["resource"])
		if unit_data == null:
			push_warning("[GameManager] Skipping unit - could not load: " + unit_info["resource"])
			continue
		
		var grid_pos = Vector2i(unit_info["col"], unit_info["row"])
		var unit = _spawn_unit(unit_scene, unit_data, grid_pos, false)
		
		if unit:
			enemy_units.append(unit)
			all_units.append(unit)
			print("[GameManager] Spawned enemy %s (%s) at: %s" % [unit_data.unit_name, unit_data.unit_type, grid_pos])
	
	# ----- PRINT ARMY COMPOSITION -----
	_print_army_composition()


## Spawns the player's deployed squad and enemy units for the current battle
## Uses RunManager.active_squad for player units
func spawn_deployed_units() -> void:
	print("[GameManager] Spawning deployed units...")
	
	# Load the Unit scene
	var unit_scene = preload("res://scenes/units/unit.tscn")
	
	if unit_scene == null:
		push_error("[GameManager] ERROR: Could not load unit scene!")
		return
	
	# Get board size (use BOARD_SIZE constant via the board)
	var board_size = board.BOARD_SIZE # Should be 10
	
	# ===================
	# SPAWN PLAYER UNITS
	# ===================
	
	# Player units spawn on bottom side (rows 7-9, like spawn_test_units)
	var player_spawn_positions: Array[Vector2i] = []
	for row in range(board_size - 3, board_size): # Rows 7, 8, 9
		for col in range(board_size): # All columns
			player_spawn_positions.append(Vector2i(col, row))
	
	# Shuffle spawn positions for variety
	player_spawn_positions.shuffle()
	
	# Spawn each unit from active squad
	var spawn_index = 0
	for unit_data in RunManager.active_squad:
		if spawn_index >= player_spawn_positions.size():
			push_warning("[GameManager] Not enough spawn positions for all player units!")
			break
		
		var spawn_pos = player_spawn_positions[spawn_index]
		
		# Make sure position is walkable and empty
		while not _is_valid_spawn_position(spawn_pos) and spawn_index < player_spawn_positions.size() - 1:
			spawn_index += 1
			spawn_pos = player_spawn_positions[spawn_index]
		
		# Use existing _spawn_unit function for consistency
		var unit = _spawn_unit(unit_scene, unit_data, spawn_pos, true)
		
		if unit:
			player_units.append(unit)
			all_units.append(unit)
			print("[GameManager] Spawned player unit: %s at %s" % [unit_data.unit_name, spawn_pos])
		
		spawn_index += 1
	
	# ===================
	# SPAWN ENEMY UNITS
	# ===================
	
	# Determine enemy count and difficulty based on region/node
	var enemy_count = _get_enemy_count()
	var enemy_unit_pool = _get_enemy_unit_pool()
	
	# Enemy units spawn on top side (rows 0-2, like spawn_test_units)
	var enemy_spawn_positions: Array[Vector2i] = []
	for row in range(3): # Rows 0, 1, 2
		for col in range(board_size): # All columns
			enemy_spawn_positions.append(Vector2i(col, row))
	
	enemy_spawn_positions.shuffle()
	
	# Spawn enemies
	spawn_index = 0
	for i in range(enemy_count):
		if spawn_index >= enemy_spawn_positions.size():
			break
		
		var spawn_pos = enemy_spawn_positions[spawn_index]
		
		# Make sure position is valid
		while not _is_valid_spawn_position(spawn_pos) and spawn_index < enemy_spawn_positions.size() - 1:
			spawn_index += 1
			spawn_pos = enemy_spawn_positions[spawn_index]
		
		# Pick random enemy from pool
		var enemy_data_path = enemy_unit_pool[randi() % enemy_unit_pool.size()]
		var enemy_data = load(enemy_data_path) as UnitData
		
		if enemy_data == null:
			push_warning("[GameManager] Could not load enemy data: %s" % enemy_data_path)
			spawn_index += 1
			continue
		
		# Use existing _spawn_unit function for consistency
		var unit = _spawn_unit(unit_scene, enemy_data, spawn_pos, false)
		
		if unit:
			enemy_units.append(unit)
			all_units.append(unit)
			print("[GameManager] Spawned enemy unit: %s at %s" % [enemy_data.unit_name, spawn_pos])
		
		spawn_index += 1
	
	# Print army composition
	_print_army_composition()

## Checks if a grid position is valid for spawning (walkable and empty)
func _is_valid_spawn_position(pos: Vector2i) -> bool:
	# Check bounds using board's BOARD_SIZE
	var board_size = board.BOARD_SIZE
	
	if pos.x < 0 or pos.x >= board_size or pos.y < 0 or pos.y >= board_size:
		return false
	
	# Check if position is valid on board
	if not board.is_valid_position(pos):
		return false
	
	# Check if tile is empty (no unit there)
	var tile_data = board.get_tile_data(pos)
	if tile_data != null:
		return false
	
	# Check terrain - avoid spawning on damaging terrain
	var terrain = board.get_terrain(pos)
	if terrain and terrain.damage_per_turn > 0:
		return false
	
	return true

## Returns the number of enemies to spawn based on current region and node
func _get_enemy_count() -> int:
	var base_count = 4
	var region_bonus = RunManager.current_region * 2 # More enemies in later regions
	var node_bonus = RunManager.current_node # Slightly more as you progress
	
	# Boss battles have more enemies!
	if RunManager.is_boss_battle:
		base_count = 6
		region_bonus = RunManager.current_region * 3
	
	# Add some randomness
	var count = base_count + region_bonus + (node_bonus / 2) + randi_range(-1, 1)
	
	# Clamp to reasonable range
	var max_enemies = 10 if not RunManager.is_boss_battle else 12
	return clamp(count, 3, max_enemies)

## Returns the enemy unit pool based on current region
func _get_enemy_unit_pool() -> Array[String]:
	var region = RunManager.current_region
	
	# Boss battles include the boss unit!
	if RunManager.is_boss_battle:
		match region:
			0: # Borderlands Boss
				return [
					"res://resources/unit_data/barbarian_berserker.tres",
					"res://resources/unit_data/barbarian_hunter.tres",
					"res://resources/unit_data/barbarian_warlord.tres", # BOSS
				]
			1: # Northern Holds Boss
				return [
					"res://resources/unit_data/barbarian_berserker.tres",
					"res://resources/unit_data/barbarian_berserker.tres",
					"res://resources/unit_data/barbarian_warlord.tres", # BOSS
				]
			2: # Southern Wastes Boss - Final Boss!
				return [
					"res://resources/unit_data/barbarian_berserker.tres",
					"res://resources/unit_data/barbarian_warlord.tres", # BOSS
					"res://resources/unit_data/barbarian_warlord.tres", # Double boss!
				]
			_:
				return ["res://resources/unit_data/barbarian_warlord.tres"]
	
	# Regular battles - different enemies for different regions
	match region:
		0: # Borderlands - basic barbarians
			return [
				"res://resources/unit_data/barbarian_pawn.tres",
				"res://resources/unit_data/barbarian_pawn.tres", # More common
				"res://resources/unit_data/barbarian_hunter.tres",
			]
		1: # Northern Holds - stronger mix
			return [
				"res://resources/unit_data/barbarian_pawn.tres",
				"res://resources/unit_data/barbarian_hunter.tres",
				"res://resources/unit_data/barbarian_berserker.tres",
			]
		2: # Southern Wastes - toughest enemies
			return [
				"res://resources/unit_data/barbarian_hunter.tres",
				"res://resources/unit_data/barbarian_berserker.tres",
				"res://resources/unit_data/barbarian_berserker.tres",
			]
		_:
			return [
				"res://resources/unit_data/barbarian_pawn.tres",
			]

			
## Loads a UnitData resource from the given path
## @param path: Full resource path to the .tres file
## @return: UnitData resource or null if loading failed
func _load_unit_data(path: String) -> UnitData:
	if not ResourceLoader.exists(path):
		push_error("[GameManager] UnitData resource not found: " + path)
		return null
	
	var resource = load(path)
	if resource == null:
		push_error("[GameManager] Failed to load UnitData: " + path)
		return null
	
	if not resource is UnitData:
		push_error("[GameManager] Resource is not UnitData: " + path)
		return null
	
	return resource


## Spawns a single unit with the given data and position
## @param unit_scene: Preloaded unit scene
## @param unit_data: UnitData resource for the unit
## @param grid_pos: Grid position to spawn at
## @param is_player: True if player-controlled unit
## @return: Spawned unit or null if failed
func _spawn_unit(unit_scene: PackedScene, unit_data: UnitData, grid_pos: Vector2i, is_player: bool) -> Unit:
	if unit_scene == null or unit_data == null:
		return null
	
	# Instantiate and add to scene tree first (required for @onready vars)
	var unit = unit_scene.instantiate()
	add_child(unit)
	
	# Initialize unit with UnitData resource
	unit.initialize(unit_data, grid_pos, is_player)
	
	# Position unit visually on the board (centered on tile)
	unit.position = board.grid_to_world(grid_pos)
	
	# Register unit in board's grid data
	board.set_tile_data(grid_pos, unit)
	
	# Connect to unit's died signal for cleanup
	unit.died.connect(_on_unit_died)
	
	# Update unit's visual display
	unit.update_visuals()
	
	return unit


## Prints a summary of both armies' composition
func _print_army_composition() -> void:
	print("\n========== ARMY COMPOSITION ==========")
	
	print("\n--- PLAYER ARMY (Roman) ---")
	for unit in player_units:
		if unit and unit.unit_data:
			print("  • %s (%s) - HP: %d, ATK: %d, DEF: %d, SPD: %d" % [
				unit.unit_data.unit_name,
				unit.unit_data.unit_type,
				unit.max_hp,
				unit.current_atk,
				unit.current_def,
				unit.current_speed
			])
	
	print("\n--- ENEMY ARMY (Barbarian) ---")
	for unit in enemy_units:
		if unit and unit.unit_data:
			print("  • %s (%s) - HP: %d, ATK: %d, DEF: %d, SPD: %d" % [
				unit.unit_data.unit_name,
				unit.unit_data.unit_type,
				unit.max_hp,
				unit.current_atk,
				unit.current_def,
				unit.current_speed
			])
	
	print("\n========================================")
	print("[GameManager] Spawned %d player units and %d enemy units" % [player_units.size(), enemy_units.size()])


## Connects to TurnManager and CombatManager signals
func connect_signals() -> void:
	# TurnManager signals for turn flow
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	
	# CombatManager signal for combat feedback
	CombatManager.combat_resolved.connect(_on_combat_resolved)
	
	# Connect UI signals
	if ui:
		ui.end_turn_pressed.connect(_on_ui_end_turn_pressed)
	
	print("[GameManager] Connected to manager signals")


## Called when the UI end turn button is pressed
func _on_ui_end_turn_pressed() -> void:
	if current_state != GameState.ENEMY_TURN and current_state != GameState.GAME_OVER:
		print("[GameManager] End turn button clicked")
		TurnManager.end_turn()

# ============================================================================
# INPUT HANDLING
# ============================================================================

## Handles tile click events from the board
## Routes to appropriate handler based on current game state
## @param grid_pos: Grid coordinates of clicked tile
func _on_tile_clicked(grid_pos: Vector2i) -> void:
	print("[GameManager] Tile clicked at: ", grid_pos, " | State: ", GameState.keys()[current_state])
	
	# Ignore input during enemy turn or game over
	if current_state == GameState.ENEMY_TURN or current_state == GameState.GAME_OVER:
		print("[GameManager] Input ignored - not player's turn or game over")
		return
	
	# Route to appropriate handler based on state
	match current_state:
		GameState.SELECTING:
			handle_tile_click_selecting(grid_pos)
		
		GameState.MOVING:
			handle_tile_click_moving(grid_pos)
		
		GameState.ATTACKING:
			handle_tile_click_attacking(grid_pos)


## Handles tile clicks when in SELECTING state
## Checks if a player unit was clicked and selects it
## @param grid_pos: Grid coordinates of clicked tile
func handle_tile_click_selecting(grid_pos: Vector2i) -> void:
	# Get whatever is at this tile position
	var clicked_unit = board.get_tile_data(grid_pos)
	
	# Check if it's a player unit that can still act
	if clicked_unit and clicked_unit.is_player_unit and TurnManager.can_unit_act(clicked_unit):
		if not clicked_unit.has_attacked or not clicked_unit.has_moved:
			select_unit(clicked_unit)
		else:
			print("Unit has already moved and attacked this turn")
	elif clicked_unit and clicked_unit.is_player_unit:
		print("Cannot select this unit, not this unit's turn")


## Handles tile clicks when in MOVING state
## Either moves the unit to valid position, attacks an enemy, or deselects
## @param grid_pos: Grid coordinates of clicked tile
func handle_tile_click_moving(grid_pos: Vector2i) -> void:
	# First check if clicking on an attackable enemy (red highlight)
	if grid_pos in valid_attack_positions:
		var target = board.get_tile_data(grid_pos)
		if target and not target.is_player_unit:
			# Attack this enemy!
			attack_unit(selected_unit, target)
			return
	
	# Check if this is a valid move position (green highlight)
	if grid_pos in valid_move_positions:
		# Check if position is empty
		var occupant = board.get_tile_data(grid_pos)
		
		if occupant == null:
			# Empty tile - move there
			move_unit_to(selected_unit, grid_pos)
		else:
			# Occupied - shouldn't happen since we filter, but handle it
			print("[GameManager] Cannot move to occupied tile")
			deselect_unit()
	elif grid_pos == selected_unit.grid_position:
		# Clicked on same unit - deselect
		deselect_unit()
	else:
		# Invalid position - check if it's another player unit to select
		var clicked_unit = board.get_tile_data(grid_pos)
		if clicked_unit and clicked_unit.is_player_unit and not clicked_unit.has_moved:
			# Switch selection to this unit
			deselect_unit()
			select_unit(clicked_unit)
		else:
			# Just deselect
			deselect_unit()


## Handles tile clicks when in ATTACKING state
## Either attacks the target enemy or deselects
## @param grid_pos: Grid coordinates of clicked tile
func handle_tile_click_attacking(grid_pos: Vector2i) -> void:
		# Safety check - selected unit may have been destroyed
	if selected_unit == null or not is_instance_valid(selected_unit):
		print("[GameManager] No valid unit selected, returning to SELECTING state")
		current_state = GameState.SELECTING
		deselect_unit()
		return
	

	# Check if there's an enemy at this position within attack range
	if grid_pos in valid_attack_positions:
		var target = board.get_tile_data(grid_pos)
		
		if target and not target.is_player_unit:
			# Attack this enemy!
			attack_unit(selected_unit, target)
			return
	
	# Not a valid attack - deselect unit
	deselect_unit()

# ============================================================================
# UNIT SELECTION
# ============================================================================

## Selects a unit and calculates valid move positions
## Highlights valid moves on the board
## @param unit: The unit to select
func select_unit(unit) -> void:
	print("[GameManager] Selected unit at: ", unit.grid_position, " (moved: ", unit.has_moved, ", attacked: ", unit.has_attacked, ")")
	
	# Deselect previous unit first
	if selected_unit and selected_unit != unit:
		board.clear_highlights()
	
	selected_unit = unit
	valid_move_positions.clear()
	valid_attack_positions.clear()
	
	# Decide what actions are available
	var can_move: bool = not unit.has_moved
	var can_attack: bool = not unit.has_attacked
	
	if can_move and can_attack:
		# Unit can do both - show moves first
		show_move_options(unit)
	elif can_move and not can_attack:
		# Can only move
		print("[GameManager] Unit can only move (already attacked)")
		show_move_options(unit)
	elif can_attack and not can_move:
		# Can only attack
		print("[GameManager] Unit can only attack (already moved)")
		show_attack_options(unit)
	else:
		# Unit has done everything
		print("[GameManager] Unit cannot do anything this turn")
		deselect_unit()
	
	# Update UI to show selected unit
	if ui:
		ui.update_unit_display(unit)


## Shows valid move options for a unit
## @param unit: The unit to show move options for
func show_move_options(unit) -> void:
	# Get valid moves
	valid_move_positions = unit.get_valid_moves(board.BOARD_SIZE)
	
	# Filter out occupied positions (only allow empty tiles for movement)
	var filtered_moves: Array[Vector2i] = []
	for pos in valid_move_positions:
		var occupant = board.get_tile_data(pos)
		if occupant == null:
			filtered_moves.append(pos)
	valid_move_positions = filtered_moves
	
	# Also find enemies in attack range (can attack without moving)
	valid_attack_positions.clear()
	if not unit.has_attacked:
		for enemy in enemy_units:
			if enemy.current_hp > 0:
				if unit.can_attack(enemy.grid_position):
					valid_attack_positions.append(enemy.grid_position)
	
	# Highlight both moves and attacks
	if valid_move_positions.size() > 0 or valid_attack_positions.size() > 0:
		# Clear existing highlights first
		board.clear_highlights()
		
		if valid_move_positions.size() > 0:
			board.add_highlights(valid_move_positions, Color.GREEN)
		if valid_attack_positions.size() > 0:
			# Add red highlights for attackable enemies (without clearing green)
			board.add_highlights(valid_attack_positions, Color.RED)
		current_state = GameState.MOVING
		print("[GameManager] Valid moves: ", valid_move_positions.size(), ", Valid attacks: ", valid_attack_positions.size())
	else:
		# No valid moves or attacks
		print("[GameManager] Unit has no valid actions")
		deselect_unit()


## Shows valid attack options for a unit
## @param unit: The unit to show attack options for
func show_attack_options(unit) -> void:
	# Find enemies in attack range
	valid_attack_positions.clear()
	
	for enemy in enemy_units:
		if enemy.current_hp > 0:
			if unit.can_attack(enemy.grid_position):
				valid_attack_positions.append(enemy.grid_position)
	
	if valid_attack_positions.size() > 0:
		board.highlight_tiles(valid_attack_positions, Color.RED)
		current_state = GameState.ATTACKING
		print("[GameManager] Unit can attack ", valid_attack_positions.size(), " enemies")
	else:
		print("[GameManager] Unit has no valid actions")
		deselect_unit()


## Deselects the current unit and clears highlights
func deselect_unit() -> void:
	print("[GameManager] Deselected unit")
	selected_unit = null
	valid_move_positions.clear()
	valid_attack_positions.clear()
	
	# Clear all board highlights
	board.clear_highlights()
	
	# Return to selecting state
	current_state = GameState.SELECTING
	
	# Hide unit info in UI
	if ui:
		ui.update_unit_display(null)

# ============================================================================
# UNIT ACTIONS
# ============================================================================

## Moves a unit to a new grid position
## Updates board data, unit position, and checks for attack options
## @param unit: The unit to move
## @param target_pos: The grid position to move to
func move_unit_to(unit, target_pos: Vector2i) -> void:
	print("[GameManager] Moving unit from ", unit.grid_position, " to ", target_pos)
	
	# Clear old position in board data
	board.set_tile_data(unit.grid_position, null)
	
	# Store old position for signal
	var old_pos: Vector2i = unit.grid_position
	
	# Update unit's grid position
	unit.grid_position = target_pos
	
	# Mark unit as having moved
	unit.has_moved = true
	
	# Animate movement with Tween for smooth sliding
	var target_world_pos: Vector2 = board.grid_to_world(target_pos)
	var tween: Tween = create_tween()
	tween.tween_property(unit, "position", target_world_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Wait for animation to finish
	await tween.finished
	
	# Set new position in board data
	board.set_tile_data(target_pos, unit)
	
	# Emit unit's moved signal
	unit.moved.emit(old_pos, target_pos)
	
	# Clear movement highlights
	board.clear_highlights()
	
	# Check if there are enemies to attack after moving
	check_attack_options(unit)


## Checks for valid attack targets after a unit moves
## If enemies are in range, highlights them and changes to ATTACKING state
## @param unit: The unit that just moved
func check_attack_options(unit) -> void:
	# Only check if unit hasn't attacked yet
	if unit.has_attacked:
		print("[GameManager] Unit has already attacked this turn")
		deselect_unit()
		return
	
	# Find enemy units in attack range
	valid_attack_positions.clear()
	
	for enemy in enemy_units:
		if enemy.current_hp > 0:
			if unit.can_attack(enemy.grid_position):
				valid_attack_positions.append(enemy.grid_position)
	
	if valid_attack_positions.size() > 0:
		# Can attack!
		board.highlight_tiles(valid_attack_positions, Color.RED)
		current_state = GameState.ATTACKING
		print("[GameManager] Unit can attack ", valid_attack_positions.size(), " enemies")
	else:
		# No attacks available, deselect
		print("[GameManager] No enemies in attack range")
		deselect_unit()


## Performs an attack from one unit to another
## Uses CombatManager to resolve the combat
## @param attacker: The attacking unit
## @param defender: The defending unit
func attack_unit(attacker, defender) -> void:
	# Safety checks - units may be null or deleted
	if attacker == null or defender == null:
		print("[GameManager] Attack cancelled - unit is null")
		deselect_unit()
		return
	
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		print("[GameManager] Attack cancelled - unit instance invalid")
		deselect_unit()
		return
	
	print("[GameManager] === ATTACKING ===")
	print("[GameManager] Attacker: ", attacker.grid_position, " -> Defender: ", defender.grid_position)
	
	# Store defender position before combat (in case defender dies)
	var defender_position = defender.position
	
	# Use CombatManager singleton to resolve combat
	# Result is handled via combat_resolved signal callback
	var result: Dictionary = CombatManager.resolve_combat(attacker, defender)
	
	# Show floating damage number at stored position
	show_damage_number(defender_position, result.damage_dealt, result.is_crit)
	
	# Check if attacker still exists before marking as attacked
	if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
		attacker.has_attacked = true
	
	# Clear highlights and deselect
	deselect_unit()

## Shows a floating damage number at the specified position
## @param pos: World position to spawn the number
## @param damage: Damage amount to display
## @param is_crit: Whether this was a critical hit (larger, yellow text)
func show_damage_number(pos: Vector2, damage: int, is_crit: bool) -> void:
	# Create a new label with the damage number script
	var damage_label = Label.new()
	var damage_script = load("res://scripts/ui/damage_number.gd")
	damage_label.set_script(damage_script)
	
	# Set the damage text
	damage_label.text = str(damage)
	damage_label.position = pos + Vector2(-20, -40)
	
	# Style critical hits differently
	if is_crit:
		damage_label.text += "!"
		damage_label.add_theme_color_override("font_color", Color.YELLOW)
		damage_label.add_theme_font_size_override("font_size", 32)
	
	add_child(damage_label)

# ============================================================================
# UNIT DEATH HANDLING
# ============================================================================

## Called when a unit dies (HP reaches 0)
## Removes unit from all tracking arrays and board
## @param unit: The unit that died
## Called when a unit dies (HP reaches 0)
## Removes unit from all tracking arrays and board
## @param unit: The unit that died
func _on_unit_died(unit) -> void:
	print("[GameManager] Unit died at: ", unit.grid_position)
	
	# Remove from board's grid data
	board.set_tile_data(unit.grid_position, null)
	
	# Remove from tracking arrays
	player_units.erase(unit)
	enemy_units.erase(unit)
	all_units.erase(unit)
	
	# If this is a player unit in a roguelike run, mark as wounded instead of dead
	if unit.is_player_unit and RunManager.run_active:
		if unit.unit_data:
			RunManager.wound_unit(unit.unit_data, 2)
			print("[GameManager] Player unit wounded: %s" % unit.unit_data.unit_name)
	
	# Remove from scene tree (deferred to avoid issues during iteration)
	unit.queue_free()
	
	# Check for game over conditions
	check_game_over()

# ============================================================================
# WIN/LOSS CONDITIONS
# ============================================================================

## Checks if the game has ended (all units of one side dead)

## Checks if the game has ended (all units of one side dead)
func check_game_over():
	if player_units.size() == 0:
		print("[GameManager] GAME OVER - You Lost!")
		current_state = GameState.GAME_OVER
		
		# Check if this is a roguelike run
		if RunManager.run_active:
			# End the run in defeat
			RunManager.end_run(false)
			# Small delay then go to defeat screen
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/game_over/defeat_screen.tscn")
		else:
			# Standalone battle - show popup
			show_game_over_popup("DEFEAT", "All your units were destroyed!")
			
	elif enemy_units.size() == 0:
		print("[GameManager] VICTORY - You Won!")
		current_state = GameState.GAME_OVER
		
		# Track enemies defeated for RunManager
		var enemies_defeated = 5 # We can make this more accurate later
		RunManager.enemies_defeated += enemies_defeated
		
		# Check if this is a roguelike run
		if RunManager.run_active:
			# Small delay to let player see victory
			await get_tree().create_timer(1.5).timeout
			
			# Check if this was a boss battle
			if RunManager.is_boss_battle:
				print("[GameManager] BOSS DEFEATED! Region complete!")
				RunManager.is_boss_battle = false
				
				# Mark region as complete and unlock next
				RunManager.complete_region(RunManager.current_region)
				
				# Check if all regions are complete
				if RunManager.current_region >= 2: # Was the final region
					# Check if all 3 regions are unlocked (meaning all beaten)
					if RunManager.regions_unlocked >= 3:
						print("[GameManager] ALL REGIONS COMPLETE! YOU WIN!")
						get_tree().change_scene_to_file("res://scenes/game_over/victory_screen.tscn")
						return
				
				# Go to reward screen, then back to world map
				get_tree().change_scene_to_file("res://scenes/rewards/reward_screen.tscn")
			else:
				# Regular battle - go to reward screen
				get_tree().change_scene_to_file("res://scenes/rewards/reward_screen.tscn")
		else:
			# Standalone battle - show popup with items
			var items_dropped: Array = []
			for i in range(3):
				var item = ItemManager.generate_random_item_drop()
				if item:
					items_dropped.append(item)
			
			var message: String = "You defeated all enemies!\n\nItems dropped:\n"
			for item in items_dropped:
				message += "• " + item.item_name + " (" + item.rarity + ")\n"
			
			show_game_over_popup("VICTORY", message)
			
func show_game_over_popup(title: String, message: String):
	# Create a simple popup
	var popup = AcceptDialog.new()
	popup.title = title
	popup.dialog_text = message
	
	# Set button text based on outcome
	if title == "VICTORY":
		popup.ok_button_text = "Next Battle"
	else:
		popup.ok_button_text = "Restart"
	
	# Add to scene
	add_child(popup)
	
	# Connect to restart when OK clicked
	popup.confirmed.connect(_on_game_over_confirmed)
	
	# Show popup
	popup.popup_centered()
	
	print("Game Over popup shown: ", title)

func _on_game_over_confirmed():
	print("[GameManager] Game over confirmed, handling restart...")
	
	# Check if this is a roguelike run
	if RunManager.run_active:
		# Go back to world map
		get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")
	else:
		# Standalone - reload current scene
		get_tree().reload_current_scene()

# ============================================================================
# TURN MANAGEMENT CALLBACKS
# ============================================================================

## Called when a new turn starts
## Resets units for the active faction and sets appropriate state
## @param faction: The faction whose turn is starting ("PLAYER" or "ENEMY")
## @param turn_number: The current turn count

func _on_turn_started(faction: String, turn_number: int) -> void:
	print("\n=== Turn ", turn_number, ": ", faction, " ===")
	
	# Update UI
	if ui:
		ui.update_turn_display(turn_number, faction)
	
	# Deselect any selected unit
	deselect_unit()
	
	# Get units to process
	var units_to_reset = player_units if faction == "PLAYER" else enemy_units
	
	# Apply terrain damage to units
	for unit in units_to_reset:
		if unit and unit.current_hp > 0:
			var terrain = board.get_terrain(unit.grid_position)
			if terrain and terrain.damage_per_turn > 0:
				print("Unit at ", unit.grid_position, " takes ", terrain.damage_per_turn, " terrain damage (", terrain.terrain_name, ")")
				unit.take_damage(terrain.damage_per_turn)
			
			# Reset turn state
			unit.reset_turn_state()
	
	if faction == "PLAYER":
		current_state = GameState.SELECTING
		print("Player's turn - select a unit to move/attack")
	else:
		current_state = GameState.ENEMY_TURN
		call_deferred("execute_enemy_turn")

## Called when a turn ends
## Cleans up selection state
## @param faction: The faction whose turn just ended
func _on_turn_ended(faction: String) -> void:
	print("[GameManager] Turn ended for: ", faction)
	
	# Clear any selection state
	deselect_unit()

# ============================================================================
# ENEMY AI
# ============================================================================

## Simple enemy AI that moves toward and attacks the nearest player unit
## Uses async/await for visual pacing between enemy actions
func execute_enemy_turn() -> void:
	print("[GameManager] Executing enemy AI...")
	
	# Brief pause before enemies start moving
	await get_tree().create_timer(0.5).timeout
	
	# Process each enemy unit
	for enemy in enemy_units:
		# Skip dead enemies (may have died during this turn)
		if enemy.current_hp <= 0:
			continue
		
		# Check if game is over (all players dead)
		if player_units.size() == 0:
			break
		
		# ----- Find nearest player unit -----
		var nearest_player = null
		var min_distance: int = 999
		
		for player in player_units:
			# Skip dead players
			if player.current_hp <= 0:
				continue
			
			# Calculate Manhattan distance
			var distance: int = abs(player.grid_position.x - enemy.grid_position.x) + \
							   abs(player.grid_position.y - enemy.grid_position.y)
			
			if distance < min_distance:
				min_distance = distance
				nearest_player = player
		
		# No valid targets found
		if nearest_player == null:
			print("[GameManager] Enemy has no valid targets")
			continue
		
		# ----- Try to attack if in range -----
		if enemy.can_attack(nearest_player.grid_position):
			print("[GameManager] Enemy attacking player at: ", nearest_player.grid_position)
			CombatManager.resolve_combat(enemy, nearest_player)
			enemy.has_attacked = true
			
			# Brief pause after attack for visual feedback
			await get_tree().create_timer(0.3).timeout
		else:
			# ----- Move closer to nearest player -----
			var valid_moves: Array[Vector2i] = enemy.get_valid_moves(board.BOARD_SIZE)
			
			if valid_moves.size() > 0:
				# Find move that gets closest to target
				var best_move: Vector2i = valid_moves[0]
				var best_distance: int = 999
				
				for move_pos in valid_moves:
					# Check if tile is occupied
					var occupant = board.get_tile_data(move_pos)
					if occupant != null:
						continue # Skip occupied tiles
					
					# Calculate distance to nearest player from this position
					var distance: int = abs(move_pos.x - nearest_player.grid_position.x) + \
									   abs(move_pos.y - nearest_player.grid_position.y)
					
					if distance < best_distance:
						best_distance = distance
						best_move = move_pos
				
				# Execute move if best position is unoccupied
				if board.get_tile_data(best_move) == null:
					# Update board data
					board.set_tile_data(enemy.grid_position, null)
					
					var old_pos: Vector2i = enemy.grid_position
					enemy.grid_position = best_move
					enemy.position = board.grid_to_world(best_move)
					enemy.has_moved = true
					
					board.set_tile_data(best_move, enemy)
					
					print("[GameManager] Enemy moved from ", old_pos, " to ", best_move)
					
					# Brief pause after move
					await get_tree().create_timer(0.3).timeout
					
					# Check if can now attack after moving
					if enemy.can_attack(nearest_player.grid_position):
						print("[GameManager] Enemy attacking after move!")
						CombatManager.resolve_combat(enemy, nearest_player)
						enemy.has_attacked = true
						await get_tree().create_timer(0.3).timeout
	
	print("[GameManager] Enemy turn complete")
	
	# End enemy turn and switch back to player
	TurnManager.end_turn()

# ============================================================================
# COMBAT CALLBACKS
# ============================================================================

## Called when CombatManager resolves combat
## Used for logging and potential UI updates
## @param result: Dictionary containing combat outcome data
func _on_combat_resolved(result: Dictionary) -> void:
	var crit_text: String = " (CRITICAL HIT!)" if result.is_crit else ""
	print("[GameManager] Combat resolved: ", result.damage_dealt, " damage dealt", crit_text)

# ============================================================================
# GLOBAL INPUT
# ============================================================================

## Handles global input events (not tile-specific)
## Currently handles manual turn ending with Enter/Space
## @param event: The input event
func _input(event: InputEvent) -> void:
	# Handle End Turn key (Enter or Space)
	if event.is_action_pressed("ui_accept"):
		# Only allow during player's turn
		if current_state != GameState.ENEMY_TURN and current_state != GameState.GAME_OVER:
			print("[GameManager] Player ended turn manually")
			deselect_unit()
			TurnManager.end_turn()
	
	# Handle cancel/deselect with Escape
	if event.is_action_pressed("ui_cancel"):
		if selected_unit != null:
			print("[GameManager] Selection cancelled")
			deselect_unit()
	
	# DEBUG: Press "I" to equip random item to selected unit
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		if selected_unit and selected_unit.is_player_unit:
			var random_item = ItemManager.generate_random_item_drop()
			if random_item:
				ItemManager.equip_item(selected_unit, random_item)
				print("[DEBUG] Equipped %s to selected unit" % random_item.item_name)
				# Update UI to show new item
				if ui:
					ui.update_unit_display(selected_unit)
			else:
				print("[DEBUG] No items available to equip")
		else:
			print("[DEBUG] Select a player unit first to equip items")
	
	# TEMPORARY: Press V to simulate victory (for testing)
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		print("[GameManager] DEBUG: Simulating victory!")
		get_tree().change_scene_to_file("res://scenes/rewards/reward_screen.tscn")
