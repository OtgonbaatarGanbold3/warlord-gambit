# CombatManager.gd
# Autoload singleton that manages all combat calculations in Warlord's Gambit.
# This centralizes combat logic so it can be easily balanced and debugged.
#
# DAMAGE FORMULA:
# Base Damage = max(1, Attacker_ATK - Defender_DEF)
# Critical Hit = 10% chance for 2x damage
#
# USAGE:
# Access globally via: CombatManager.resolve_combat(attacker, defender)
#
# SETUP:
# 1. Project → Project Settings → Autoload tab
# 2. Add this script with Node Name: "CombatManager"
# 3. Click "Add" to register as singleton

extends Node

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when combat begins between two units
## Connect to this for combat animations, sound effects, etc.
## @param attacker: The unit initiating the attack
## @param defender: The unit being attacked
signal combat_started(attacker, defender)

## Emitted when combat calculation is complete
## Contains full result data for UI updates, logging, etc.
## @param result: Dictionary with combat outcome details
signal combat_resolved(result: Dictionary)

## Emitted when a unit dies as a result of combat
## Connect to this for death animations, score updates, etc.
## @param unit: The unit that died
signal unit_died(unit)

# ============================================================================
# DAMAGE CALCULATION
# ============================================================================

## Calculates damage dealt from an attack
## Uses ATK vs DEF formula with critical hit chance
## @param attacker_atk: Attacker's current attack stat
## @param defender_def: Defender's current defense stat
## @return: Dictionary with "damage" (int) and "is_crit" (bool)
func calculate_damage(attacker_atk: int, defender_def: int) -> Dictionary:
	# Calculate base damage: ATK minus DEF, minimum 1
	# This ensures even heavily armored units take some damage
	var base_damage: int = max(1, attacker_atk - defender_def)
	
	# 10% critical hit chance
	# Critical hits deal double damage - great for high-risk moments!
	var is_crit: bool = randf() < 0.1
	var final_damage: int = base_damage * 2 if is_crit else base_damage
	
	# Debug output
	print("[CombatManager] Damage calc: ATK ", attacker_atk, " vs DEF ", defender_def)
	print("[CombatManager] Base damage: ", base_damage, ", Crit: ", is_crit, ", Final: ", final_damage)
	
	return {
		"damage": final_damage,
		"is_crit": is_crit
	}

# ============================================================================
# COMBAT RESOLUTION
# ============================================================================

## Resolves a complete combat exchange between two units
## Handles damage calculation, application, and death checking
## @param attacker: The unit performing the attack
## @param defender: The unit receiving the attack
## @return: Dictionary with full combat results
func resolve_combat(attacker, defender) -> Dictionary:
	print("[CombatManager] === COMBAT START ===")
	print("[CombatManager] ", attacker.unit_data.unit_name if attacker.unit_data else "Attacker",
		  " attacks ", defender.unit_data.unit_name if defender.unit_data else "Defender")
	
	# Emit signal for combat start (UI can show attack animation)
	combat_started.emit(attacker, defender)
	
	# Calculate damage using ATK vs DEF formula
	var damage_result: Dictionary = calculate_damage(attacker.current_atk, defender.current_def)
	
	# Apply damage to defender and get remaining HP
	var remaining_hp: int = defender.take_damage(damage_result.damage)
	
	# Check if the defender was killed
	var defender_died: bool = remaining_hp <= 0
	if defender_died:
		print("[CombatManager] ", defender.unit_data.unit_name if defender.unit_data else "Defender", " was KILLED!")
		unit_died.emit(defender)
	else:
		print("[CombatManager] Defender HP remaining: ", remaining_hp)
	
	# Build comprehensive result dictionary
	var result: Dictionary = {
		"attacker": attacker,
		"defender": defender,
		"damage_dealt": damage_result.damage,
		"is_crit": damage_result.is_crit,
		"defender_survived": not defender_died,
		"defender_hp": remaining_hp
	}
	
	# Emit signal with full results (UI can show damage numbers, etc.)
	combat_resolved.emit(result)
	
	print("[CombatManager] === COMBAT END ===")
	
	return result

# ============================================================================
# COMBAT VALIDATION
# ============================================================================

## Checks if two units can engage in combat
## Validates all preconditions before allowing an attack
## @param attacker: The unit that wants to attack
## @param defender: The potential target
## @return: True if combat is allowed, false otherwise
func can_units_fight(attacker, defender) -> bool:
	# Check for null references
	if not attacker or not defender:
		print("[CombatManager] Cannot fight: null reference")
		return false
	
	# Check if attacker already used their attack this turn
	if attacker.has_attacked:
		print("[CombatManager] Cannot fight: attacker already attacked this turn")
		return false
	
	# Check if defender is still alive
	if defender.current_hp <= 0:
		print("[CombatManager] Cannot fight: defender is already dead")
		return false
	
	# Check if units are on the same faction (no friendly fire!)
	if attacker.faction == defender.faction:
		print("[CombatManager] Cannot fight: same faction (", attacker.faction, ")")
		return false
	
	# All checks passed - combat is allowed
	print("[CombatManager] Combat validation passed")
	return true

# ============================================================================
# UTILITY METHODS
# ============================================================================

## Checks if an attacker can reach a defender based on attack range
## @param attacker: The attacking unit
## @param defender: The target unit
## @return: True if defender is within attack range
func is_in_range(attacker, defender) -> bool:
	if not attacker or not defender:
		return false
	
	# Calculate Manhattan distance between units
	var distance: int = abs(attacker.grid_position.x - defender.grid_position.x) + \
						abs(attacker.grid_position.y - defender.grid_position.y)
	
	var attack_range: int = attacker.get_attack_range()
	var in_range: bool = distance <= attack_range
	
	print("[CombatManager] Range check: distance ", distance, ", range ", attack_range, ", in_range: ", in_range)
	
	return in_range


## Performs a full combat attempt with all validation
## Combines can_units_fight() and is_in_range() checks
## @param attacker: The attacking unit
## @param defender: The target unit
## @return: Dictionary with result, or null if combat not allowed
func attempt_combat(attacker, defender):
	# Validate combat is allowed
	if not can_units_fight(attacker, defender):
		print("[CombatManager] Combat attempt failed validation")
		return null
	
	# Check if target is in range
	if not is_in_range(attacker, defender):
		print("[CombatManager] Combat attempt failed: target out of range")
		return null
	
	# All checks passed - resolve combat
	return resolve_combat(attacker, defender)
