# TurnManager.gd
# Autoload singleton that manages turn order and game phases in Warlord's Gambit.
# Controls the flow of gameplay between player and enemy turns.
#
# GAME FLOW:
# 1. PLAYER_PLANNING - Player positions units, selects formation
# 2. PLAYER_ACTION - Player units move and attack
# 3. ENEMY_TURN - AI controls enemy units
# 4. Back to PLAYER_PLANNING (or BATTLE_END if victory/defeat)
#
# USAGE:
# Access globally via: TurnManager.end_turn(), TurnManager.can_unit_act(unit), etc.
#
# SETUP:
# 1. Project → Project Settings → Autoload tab
# 2. Add this script with Node Name: "TurnManager"
# 3. Click "Add" to register as singleton

extends Node

# ============================================================================
# ENUMS
# ============================================================================

## Game phases that control what actions are available
## PLAYER_PLANNING: Pre-battle positioning phase
## PLAYER_ACTION: Player's units can move and attack
## ENEMY_TURN: AI controls enemy units
## BATTLE_END: Combat has concluded (victory or defeat)
enum Phase {
	PLAYER_PLANNING,
	PLAYER_ACTION,
	ENEMY_TURN,
	BATTLE_END
}

# ============================================================================
# PROPERTIES
# ============================================================================

## Current turn number (increments each time player's turn starts)
var current_turn: int = 1

## Current game phase (determines available actions)
var current_phase: Phase = Phase.PLAYER_PLANNING

## Which faction is currently active ("PLAYER" or "ENEMY")
var active_faction: String = "PLAYER"

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a new turn begins
## @param faction: The faction whose turn is starting
## @param turn_number: The current turn count
signal turn_started(faction: String, turn_number: int)

## Emitted when a turn ends
## @param faction: The faction whose turn just ended
signal turn_ended(faction: String)

## Emitted when the game phase changes
## @param new_phase: The Phase enum value of the new phase
signal phase_changed(new_phase: Phase)

# ============================================================================
# INITIALIZATION
# ============================================================================

## Called when the node enters the scene tree
func _ready() -> void:
	print("[TurnManager] Initialized - Turn ", current_turn, ", Phase: ", Phase.keys()[current_phase])

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Starts a new turn for the specified faction
## Increments turn counter on player turns and sets appropriate phase
## @param faction: "PLAYER" or "ENEMY"
func start_turn(faction: String) -> void:
	print("[TurnManager] === STARTING TURN ===")
	
	# Set the active faction
	active_faction = faction
	
	# Increment turn number only on player turns
	# This way turn 1 = first full round, turn 2 = second round, etc.
	if faction == "PLAYER":
		current_turn += 1
		print("[TurnManager] Turn counter incremented to: ", current_turn)
	
	# Set the appropriate phase based on faction
	if faction == "PLAYER":
		set_phase(Phase.PLAYER_PLANNING)
	else:
		set_phase(Phase.ENEMY_TURN)
	
	# Emit signal for other systems to react
	turn_started.emit(faction, current_turn)
	
	print("[TurnManager] Turn ", current_turn, " started - ", faction, "'s turn")


## Ends the current turn and starts the next faction's turn
## Automatically switches between PLAYER and ENEMY
func end_turn() -> void:
	print("[TurnManager] === ENDING TURN ===")
	
	# Emit signal before switching
	turn_ended.emit(active_faction)
	print("[TurnManager] ", active_faction, "'s turn ended")
	
	# Determine next faction (toggle between PLAYER and ENEMY)
	var next_faction: String = "ENEMY" if active_faction == "PLAYER" else "PLAYER"
	
	# Start the next faction's turn
	start_turn(next_faction)

# ============================================================================
# PHASE MANAGEMENT
# ============================================================================

## Changes the current game phase
## Emits phase_changed signal for UI updates, etc.
## @param new_phase: The Phase enum value to switch to
func set_phase(new_phase: Phase) -> void:
	var old_phase_name: String = Phase.keys()[current_phase]
	current_phase = new_phase
	var new_phase_name: String = Phase.keys()[new_phase]
	
	# Emit signal for UI and other systems
	phase_changed.emit(new_phase)
	
	print("[TurnManager] Phase changed: ", old_phase_name, " → ", new_phase_name)


## Transitions from planning to action phase
## Call this when player confirms their unit positions
func start_action_phase() -> void:
	if current_phase == Phase.PLAYER_PLANNING:
		set_phase(Phase.PLAYER_ACTION)
		print("[TurnManager] Player action phase started - units can now move and attack")


## Ends the battle (victory or defeat)
## @param player_won: True if player won, false if player lost
func end_battle(player_won: bool) -> void:
	set_phase(Phase.BATTLE_END)
	if player_won:
		print("[TurnManager] BATTLE END - VICTORY!")
	else:
		print("[TurnManager] BATTLE END - DEFEAT!")

# ============================================================================
# UNIT STATE MANAGEMENT
# ============================================================================

## Resets turn state for all units in the array
## Call this at the start of each turn to allow units to act again
## @param units: Array of Unit nodes to reset
func reset_all_units(units: Array) -> void:
	print("[TurnManager] Resetting turn state for ", units.size(), " units")
	
	for unit in units:
		if unit and unit.has_method("reset_turn_state"):
			unit.reset_turn_state()
		else:
			print("[TurnManager] Warning: Unit missing reset_turn_state method")

# ============================================================================
# ACTION VALIDATION
# ============================================================================

## Checks if a unit is allowed to perform actions this turn
## Validates faction, phase, and unit status
## @param unit: The unit to check
## @return: True if unit can act, false otherwise
func can_unit_act(unit) -> bool:
	# Null check
	if not unit:
		print("[TurnManager] can_unit_act: null unit")
		return false
	
	# Determine unit's faction based on is_player_unit flag
	var unit_faction: String = "PLAYER" if unit.is_player_unit else "ENEMY"
	
	# Must be this faction's turn
	if unit_faction != active_faction:
		print("[TurnManager] can_unit_act: wrong faction (unit: ", unit_faction, ", active: ", active_faction, ")")
		return false
	
	# Must be in an action phase (not planning or battle end)
	var in_action_phase: bool = (current_phase == Phase.PLAYER_ACTION or current_phase == Phase.ENEMY_TURN)
	if not in_action_phase:
		print("[TurnManager] can_unit_act: not in action phase (current: ", Phase.keys()[current_phase], ")")
		return false
	
	# Unit must be alive
	if unit.current_hp <= 0:
		print("[TurnManager] can_unit_act: unit is dead")
		return false
	
	print("[TurnManager] can_unit_act: unit CAN act")
	return true


## Checks if a unit can still move this turn
## @param unit: The unit to check
## @return: True if unit can move
func can_unit_move(unit) -> bool:
	if not can_unit_act(unit):
		return false
	
	if unit.has_moved:
		print("[TurnManager] can_unit_move: unit already moved")
		return false
	
	return true


## Checks if a unit can still attack this turn
## @param unit: The unit to check
## @return: True if unit can attack
func can_unit_attack(unit) -> bool:
	if not can_unit_act(unit):
		return false
	
	if unit.has_attacked:
		print("[TurnManager] can_unit_attack: unit already attacked")
		return false
	
	return true

# ============================================================================
# UTILITY METHODS
# ============================================================================

## Gets the name of the current phase as a string
## Useful for UI display
## @return: Phase name as String
func get_phase_name() -> String:
	return Phase.keys()[current_phase]


## Gets a summary of current turn state
## Useful for debugging and UI
## @return: Dictionary with turn info
func get_turn_info() -> Dictionary:
	return {
		"turn": current_turn,
		"phase": get_phase_name(),
		"active_faction": active_faction
	}
